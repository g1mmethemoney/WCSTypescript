import { RunService } from "@rbxts/services";
import { getActiveHandler, logError, logMessage } from "./utility";
import { Janitor } from "@rbxts/janitor";
import { rootProducer } from "state/rootProducer";
import { SelectCharacterData } from "state/selectors";
import { GetRegisteredStatusEffectConstructor, StatusData, StatusEffect } from "./statusEffect";
import { FlagWithData, Flags } from "./flags";
import Signal from "@rbxts/rbx-better-signal";

export interface CharacterData {
    statusEffects: Map<string, StatusData>;
    defaultProps: AffectableHumanoidProps;
}

export type AffectableHumanoidProps = Pick<Humanoid, "WalkSpeed" | "JumpPower" | "AutoRotate" | "JumpHeight">;

export class Character {
    private static readonly currentCharMap = new Map<Instance, Character>();
    public static readonly CharacterCreated = new Signal<(Character: Character) => void>();
    public static readonly CharacterDestroyed = new Signal<(Character: Character) => void>();

    public readonly Instance: Instance;
    public readonly Humanoid: Humanoid;

    public readonly StatusEffectAdded = new Signal<(Status: StatusEffect) => void>();
    public readonly StatusEffectRemoved = new Signal<(Status: StatusEffect) => void>();
    public readonly DamageTaken = new Signal<(Damage: number) => void>();
    public readonly Destroyed = new Signal();

    private readonly janitor = new Janitor();
    private readonly statusEffects: Map<string, StatusEffect> = new Map();
    private defaultsProps: AffectableHumanoidProps = {
        WalkSpeed: 16,
        JumpPower: 100,
        AutoRotate: true,
        JumpHeight: 7.2,
    };

    constructor(Instance: Instance);
    /**
     * @internal Reserved for internal usage
     */
    constructor(Instance: Instance, canCreateClient: (typeof Flags)["CanCreateCharacterClient"]);
    constructor(Instance: Instance, canCreateClient?: (typeof Flags)["CanCreateCharacterClient"]) {
        if (RunService.IsClient() && canCreateClient !== Flags.CanCreateCharacterClient) {
            logError(
                `Attempted to manually create a character on client. \n On client side character are created by the handler automatically, \n doing this manually can lead to a possible desync`,
            );
        }

        if (Character.currentCharMap.get(Instance)) {
            logError(`Attempted to create 2 different characters over a same instance.`);
        }

        if (!getActiveHandler()) {
            logError(`Attempted to instantiate a character before server has started.`);
        }

        const humanoid = Instance.FindFirstChildOfClass("Humanoid");
        if (!humanoid) {
            logError(`Attempted to instantiate a character over an instance without humanoid.`);
            error(``);
        }

        this.Instance = Instance;
        this.Humanoid = humanoid;

        Character.currentCharMap.set(Instance, this);
        Character.CharacterCreated.Fire(this);

        this.setupReplication_Client();

        this.janitor.Add(this.DamageTaken);
        this.janitor.Add(this.Destroyed);

        this.updateHumanoidProps();

        if (RunService.IsServer()) {
            rootProducer.setCharacterData(this.Instance, this._packData());
        }
    }

    private updateHumanoidProps() {
        const statuses: StatusEffect[] = [];
        this.statusEffects.forEach((Status) => Status.GetHumanoidData() ?? statuses.push(Status));

        if (statuses.isEmpty()) return;
        const propsToApply = table.clone(this.defaultsProps);
        const incPriorityList: Record<keyof AffectableHumanoidProps, number> = {
            WalkSpeed: 0,
            JumpPower: 0,
            AutoRotate: 0,
            JumpHeight: 0,
        };

        let previousSetMPriority: number | undefined = undefined;
        statuses.forEach((StatusEffect) => {
            const humanoidData = StatusEffect.GetHumanoidData();
            if (!humanoidData) return;

            const mode = humanoidData.Mode;
            const priority = humanoidData.Priority;
            if (mode === "Increment" && !previousSetMPriority) {
                for (const [PropertyName, Value] of pairs(humanoidData.Props)) {
                    if (typeIs(Value, "number")) {
                        propsToApply[PropertyName] = (Value + propsToApply[PropertyName as never]) as never;
                    } else if (priority > incPriorityList[PropertyName]) {
                        propsToApply[PropertyName as never] = Value as never;
                        incPriorityList[PropertyName] = priority;
                    }
                }
            } else if (mode === "Set" && (!previousSetMPriority || priority > previousSetMPriority)) {
                previousSetMPriority = priority;
                for (const [PropertyName, Value] of pairs(humanoidData.Props)) {
                    propsToApply[PropertyName as never] = Value as never;
                }
            }
        });

        for (const [PropertyName, Value] of pairs(propsToApply)) {
            this.Humanoid[PropertyName as never] = Value as never;
        }
    }

    public Destroy() {
        this.janitor.Cleanup();
        Character.currentCharMap.delete(this.Instance);

        if (RunService.IsServer()) {
            rootProducer.deleteCharacterData(this.Instance);
        }

        Character.CharacterDestroyed.Fire(this);
        this.Destroyed.Fire();
    }

    /**
     * @internal Reserved for internal usage
     */
    public _addStatus(Status: StatusEffect) {
        this.statusEffects.set(Status.GetId(), Status);
        this.StatusEffectAdded.Fire(Status);

        this.updateHumanoidProps();
        const conn = Status.HumanoidDataChanged.Connect(() => this.updateHumanoidProps());

        this.janitor.Add(conn);

        Status.Destroyed.Once(() => {
            conn.Disconnect();
            this.statusEffects.delete(Status.GetId());
            this.StatusEffectRemoved.Fire(Status);
            this.updateHumanoidProps();
        });
    }

    /**
     * @internal Reserved for internal usage
     */
    public _packData(): CharacterData {
        const packedStatusEffect = new Map<string, StatusData>();
        this.statusEffects.forEach((Status, Id) => packedStatusEffect.set(Id, Status._packData()));

        return {
            statusEffects: packedStatusEffect,
            defaultProps: this.defaultsProps,
        };
    }

    private setupReplication_Client() {
        if (!RunService.IsClient()) return;
        if (!getActiveHandler()) return;

        const processStatusAddition = (Data: StatusData, Id: string) => {
            const constructor = GetRegisteredStatusEffectConstructor(Data.className);
            if (!constructor) {
                logError(
                    `Replication Error: Could not find a registered StatusEffect with name {statusData.className}. \n Try doing :RegisterDirectory() on the file directory.`,
                );
            }

            const newStatus = new constructor!(
                this as never,
                {
                    flag: Flags.CanAssignCustomId,
                    data: Id,
                } as never,
            );
            this.statusEffects.set(Id, newStatus);
        };

        const disconnect = rootProducer.subscribe(SelectCharacterData(this.Instance), (CharacterData) => {
            if (!CharacterData) return;

            CharacterData.statusEffects.forEach((StatusData, Id) => {
                if (!this.statusEffects.get(Id)) {
                    processStatusAddition(StatusData, Id);
                }
            });

            this.statusEffects.forEach((Status, Id) => {
                if (!CharacterData.statusEffects.has(Id)) {
                    Status.Destroy();
                }
            });

            if (CharacterData.defaultProps !== this.defaultsProps) this.SetDefaultProps(CharacterData.defaultProps);
        });
        this.janitor.Add(disconnect);
    }

    public SetDefaultProps(Props: AffectableHumanoidProps) {
        this.defaultsProps = Props;
        if (RunService.IsServer()) {
            rootProducer.patchCharacterData(this.Instance, {
                defaultProps: Props,
            });
        }
    }

    public GetDefaultsProps() {
        return table.clone(this.defaultsProps);
    }

    public static GetCharacterMap() {
        return table.clone(this.currentCharMap) as ReadonlyMap<Instance, Character>;
    }

    public static GetCharacterFromInstance(Instance: Instance) {
        return this.currentCharMap.get(Instance);
    }
}
