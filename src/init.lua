type void = nil;

type Callback = () -> void;

export type Server = {
    FilterReplicatedCharacters: (Player, Character) -> boolean;
    Start: (Server) -> void;
    RegisterDirectory: (Server, Instance) -> void;
    IsActive: () -> boolean;
}

export type Client = {
    Start: (Client) -> void;
    RegisterDirectory: (Client, Instance) -> void;
    IsActive: () -> boolean;
}

export type ReadonlySignal<T = Callback> = {
    Connect: (ReadonlySignal<T>, T) -> RBXScriptConnection;
    Once: (ReadonlySignal<T>, T) -> RBXScriptConnection;
    Wait: (ReadonlySignal<T>) -> void;
}

type StatusEffectState = {
    IsActive: boolean;
}
type Partial_StatusEffectState = {
    IsActive: boolean?;
}

export type Moveset = {
    Name: string;
    Skills: {SkillConstructor<any, any, any>};
}

export type HumanoidDataProps = {
    WalkSpeed: {Mode: ("Set" | "Increment"), Value: number}?;
    JumpPower: {Mode: ("Set" | "Increment"), Value: number}?;
    JumpHeight: {Mode: ("Set" | "Increment"), Value: number}?;
    AutoRotate: {Mode: ("Set" | "Increment"), Value: boolean}?;
}

export type HumanoidData = {
    Props: HumanoidDataProps;
    Priority: number;
}

export type StatusEffect<T = any> = {
    MetadataChanged: ReadonlySignal<(T?, T?) -> void>;
    StateChanged: ReadonlySignal<(StatusEffectState, StatusEffectState) -> void>;
    HumanoidDataChanged: ReadonlySignal<(HumanoidData?, HumanoidData?) -> void>;
    Destroyed: ReadonlySignal<Callback>;
    Started: ReadonlySignal<Callback>;
    Ended: ReadonlySignal<Callback>;
    Character: Character;

    DestroyOnEnd: boolean;
    
    Start: (StatusEffect<T>, number?) -> void;
    End: (StatusEffect<T>) -> void;
    Pause: (StatusEffect<T>) -> void;
    Resume: (StatusEffect<T>) -> void;
    Stop: (StatusEffect<T>) -> void;
    SetHumanoidData: (StatusEffect<T>, HumanoidDataProps, number?) -> void;
    ClearHumanoidData: (StatusEffect<T>) -> void;
    ClearMetadata: (StatusEffect<T>) -> void;
    SetState: (StatusEffect<T>, Partial_StatusEffectState) -> void;
    SetMetadata: (StatusEffect<T>, T) -> void;
    GetState: (StatusEffect<T>) -> StatusEffectState;
    GetHumanoidData: (StatusEffect<T>) -> HumanoidData;
    GetMetadata: (StatusEffect<T>) -> T;
    IsDestroyed: (StatusEffect<T>) -> boolean;
    GetId: (StatusEffect<T>) -> string;
    Destroy: (StatusEffect<T>) -> void;
    Construct: (StatusEffect<T>) -> void;
    OnStartServer: (StatusEffect<T>) -> void;
    OnStartClient: (StatusEffect<T>) -> void;
    OnEndClient: (StatusEffect<T>) -> void;
    OnEndServer: (StatusEffect<T>) -> void;
    CreateDamageContainer: (StatusEffect<T>, number) -> DamageContainer,
}

type StatusEffectConstructor<T = any> = {
    new: (Character) -> StatusEffect<T>
}

type SkillState = {
    IsActive: boolean,
    Debounce: boolean,
    TimerEndTimestamp: number?,
    StarterParams: any?,
}

type SkillData = {
    state: SkillState,
}

type RbxScriptConnection = {
    Disconnect: (RbxScriptConnection) -> void;
}

type BooleanOrString = boolean | string;
type Janitor = {
	ClassName: "Janitor",
	CurrentlyCleaning: boolean,
	SuppressInstanceReDestroy: boolean,

	Add: <T>(self: Janitor, Object: T, MethodName: BooleanOrString?, Index: any?) -> T,
	AddPromise: <T>(self: Janitor, PromiseObject: T) -> T,

	Remove: (self: Janitor, Index: any) -> Janitor,
	RemoveNoClean: (self: Janitor, Index: any) -> Janitor,

	RemoveList: (self: Janitor, ...any) -> Janitor,
	RemoveListNoClean: (self: Janitor, ...any) -> Janitor,

	Get: (self: Janitor, Index: any) -> any?,
	GetAll: (self: Janitor) -> {[any]: any},

	Cleanup: (self: Janitor) -> (),
	Destroy: (self: Janitor) -> (),

	LinkToInstance: (self: Janitor, Object: Instance, AllowMultiple: boolean?) -> RBXScriptConnection,
	LegacyLinkToInstance: (self: Janitor, Object: Instance, AllowMultiple: boolean?) -> RbxScriptConnection,

	LinkToInstances: (self: Janitor, ...Instance) -> Janitor,
}

type DamageContainer = {
    Damage: number;
    Source: Skill<any, any, any> | StatusEffect<any> | void;
}

export type Skill<StarterParams, ClientToServerMessage, ServerToClientMessage> = {
    Janitor: Janitor,
    Started: ReadonlySignal<Callback>,
    Ended: ReadonlySignal<Callback>,
    StateChanged: ReadonlySignal<(NewState: SkillState, OldState: SkillState) -> ()>,
    Destroyed: ReadonlySignal<Callback>,
    StartCondition: () -> boolean,
    MutualExclusives: {StatusEffectConstructor<any>},
    Requirements: {StatusEffectConstructor<any>},
    Player: Player?,
    Character: Character,
    ApplyCooldown: (Skill<StarterParams, ClientToServerMessage, ServerToClientMessage>, number) -> void,
    HandleClientMessage: (Skill<StarterParams, ClientToServerMessage, ServerToClientMessage>, ClientToServerMessage) -> void,
    HandleServerMessage: (Skill<StarterParams, ClientToServerMessage, ServerToClientMessage>, ServerToClientMessage) -> void,
    SendMessageToClient: (Skill<StarterParams, ClientToServerMessage, ServerToClientMessage>, ServerToClientMessage) -> void,
    SendMessageToServer: (Skill<StarterParams, ClientToServerMessage, ServerToClientMessage>, ClientToServerMessage) -> void,
    GetName: (Skill<StarterParams, ClientToServerMessage, ServerToClientMessage>) -> string,
    OnStartServer: (Skill<StarterParams, ClientToServerMessage, ServerToClientMessage>, StarterParams) -> void,
    OnStartClient: (Skill<StarterParams, ClientToServerMessage, ServerToClientMessage>, StarterParams) -> void,
    OnEndServer: (Skill<StarterParams, ClientToServerMessage, ServerToClientMessage>) -> void,
    OnEndClient: (Skill<StarterParams, ClientToServerMessage, ServerToClientMessage>) -> void,
    GetState: (Skill<StarterParams, ClientToServerMessage, ServerToClientMessage>) -> SkillState,
    End: (Skill<StarterParams, ClientToServerMessage, ServerToClientMessage>) -> void,
    CreateDamageContainer: (Skill<StarterParams, ClientToServerMessage, ServerToClientMessage>, number) -> DamageContainer,
    Destroy: (Skill<StarterParams, ClientToServerMessage, ServerToClientMessage>) -> void,
}

export type SkillConstructor<StarterParams, ClientToServerMessage, ServerToClientMessage> = {
    new: (Character) -> Skill<StarterParams, ClientToServerMessage, ServerToClientMessage>
}

export type AffectableHumanoidProps = {
    WalkSpeed: number;
    JumpPower: number;
    JumpHeight: number;
    AutoRotate: boolean;
}

export type HoldableSkill<StarterParams, ClientToServerMessage, ServerToClientMessage> = Skill<StarterParams, ClientToServerMessage, ServerToClientMessage> & {
    SetMaxHoldTime: (HoldableSkill<StarterParams, ClientToServerMessage, ServerToClientMessage>, number) -> void,
    GetMaxHoldTime: (HoldableSkill<StarterParams, ClientToServerMessage, ServerToClientMessage>) -> number,
}

export type Character = {
    Instance: Instance;
    Humanoid: Humanoid;
    Player: Player?;

    StatusEffectAdded: ReadonlySignal<(StatusEffect<any>) -> void>;
    StatusEffectRemoved: ReadonlySignal<(StatusEffect<any>) -> void>;
    DamageTaken: ReadonlySignal<(number) -> void>;
    Destroyed: ReadonlySignal<Callback>;

    Destroy: () -> void;
    GetId: () -> string;

    SetDefaultProps: (Character, AffectableHumanoidProps) -> void;
    GetDefaultProps: (Character) -> AffectableHumanoidProps;
    GetAllStatusEffects: (Character) -> {StatusEffect<any>};
    GetAllActiveStatusEffects: (Character) -> {StatusEffect<any>};
    GetAllStatusEffectsOfType: (Character, StatusEffectConstructor<any>) -> {StatusEffect<any>};
    GetAllActiveStatusEffectsOfType: (Character, StatusEffectConstructor<any>) -> {StatusEffect<any>};
    HasStatusEffects: (Character, {StatusEffectConstructor<any>}) -> boolean;
    GetSkillFromString: (Character, string) -> Skill<any, any, any>?;
    GetSkillFromConstructor: (Character, SkillConstructor<any, any, any>) -> Skill<any, any, any>?;
    ApplyMoveset: (Character, Moveset) -> void;
    GetMoveset: (Character) -> Moveset;
    ClearMoveset: (Character) -> void;
    ApplySkillsFromMoveset: (Character, Moveset) -> void;
    TakeDamage: (DamageContainer) -> DamageContainer;
}

type CharacterClass = {
    CharacterCreated: ReadonlySignal<(Character) -> void>;
    CharacterDestroyed: ReadonlySignal<(Character) -> void>;

    new: (Instance) -> Character;
    GetCharacterMap: () -> {[Instance]: Character};
    GetCharacterFromInstance: (Instance) -> Character?;
}

export type WCS = {
    CreateServer: () -> Server;
    CreateClient: () -> Client;
    CreateMoveset: (string) -> Moveset;
    RegisterStatusEffect: (string) -> StatusEffect<any> & StatusEffectConstructor<any>;
    RegisterSkill: (string) -> Skill<any, any, any> & SkillConstructor<any, any, any>;
    RegisterHoldableSkill: (string) -> HoldableSkill<any, any, any> & SkillConstructor<any, any, any>;
    Character: CharacterClass;
    Types: ModuleScript;
}

local TS = script:FindFirstChild("include") and require(script:FindFirstChild("include").RuntimeLib) or _G[script]

local exports = {}
for _k, _v in TS.import(script, script, "exports") or {} do
	exports[_k] = _v
end

return exports :: WCS
