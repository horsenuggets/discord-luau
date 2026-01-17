--[[

Types

Type definitions for Discord API structures. These types match the Discord API v10
specification and are used throughout the library.

--]]

-- Forward declarations for circular references
export type Client = any
export type Guild = any
export type Channel = any
export type Message = any
export type User = any
export type Member = any
export type Role = any

-- Snowflake is a string representation of a 64-bit ID
export type Snowflake = string

-- API User object
export type APIUser = {
    accent_color: number?,
    avatar: string?,
    avatar_decoration_data: {
        asset: string,
        sku_id: string,
    }?,
    banner: string?,
    bot: boolean?,
    discriminator: string,
    email: string?,
    flags: number?,
    global_name: string?,
    id: Snowflake,
    locale: string?,
    mfa_enabled: boolean?,
    premium_type: number?,
    public_flags: number?,
    system: boolean?,
    username: string,
    verified: boolean?,
}

-- API Guild Member object
export type APIMember = {
    avatar: string?,
    communication_disabled_until: string?,
    deaf: boolean,
    flags: number,
    joined_at: string,
    mute: boolean,
    nick: string?,
    pending: boolean?,
    permissions: string?,
    premium_since: string?,
    roles: { Snowflake },
    user: APIUser?,
}

-- API Role object
export type APIRole = {
    color: number,
    hoist: boolean,
    icon: string?,
    id: Snowflake,
    managed: boolean,
    mentionable: boolean,
    name: string,
    permissions: string,
    position: number,
    tags: {
        bot_id: Snowflake?,
        integration_id: Snowflake?,
        premium_subscriber: boolean?,
        subscription_listing_id: Snowflake?,
        available_for_purchase: boolean?,
        guild_connections: boolean?,
    }?,
    unicode_emoji: string?,
}

-- API Channel object
export type APIChannel = {
    application_id: Snowflake?,
    applied_tags: { Snowflake }?,
    available_tags: { APIForumTag }?,
    bitrate: number?,
    default_auto_archive_duration: number?,
    default_forum_layout: number?,
    default_reaction_emoji: APIDefaultReaction?,
    default_sort_order: number?,
    default_thread_rate_limit_per_user: number?,
    flags: number?,
    guild_id: Snowflake?,
    icon: string?,
    id: Snowflake,
    last_message_id: Snowflake?,
    last_pin_timestamp: string?,
    managed: boolean?,
    member: APIThreadMember?,
    member_count: number?,
    message_count: number?,
    name: string?,
    nsfw: boolean?,
    owner_id: Snowflake?,
    parent_id: Snowflake?,
    permission_overwrites: { APIOverwrite }?,
    permissions: string?,
    position: number?,
    rate_limit_per_user: number?,
    recipients: { APIUser }?,
    rtc_region: string?,
    thread_metadata: APIThreadMetadata?,
    topic: string?,
    total_message_sent: number?,
    type: number,
    user_limit: number?,
    video_quality_mode: number?,
}

export type APIForumTag = {
    emoji_id: Snowflake?,
    emoji_name: string?,
    id: Snowflake,
    moderated: boolean,
    name: string,
}

export type APIDefaultReaction = {
    emoji_id: Snowflake?,
    emoji_name: string?,
}

export type APIThreadMember = {
    flags: number,
    id: Snowflake?,
    join_timestamp: string,
    member: APIMember?,
    user_id: Snowflake?,
}

export type APIThreadMetadata = {
    archive_timestamp: string,
    archived: boolean,
    auto_archive_duration: number,
    create_timestamp: string?,
    invitable: boolean?,
    locked: boolean,
}

export type APIOverwrite = {
    allow: string,
    deny: string,
    id: Snowflake,
    type: number,
}

-- API Message object
export type APIMessage = {
    activity: APIMessageActivity?,
    application: APIApplication?,
    application_id: Snowflake?,
    attachments: { APIAttachment },
    author: APIUser,
    channel_id: Snowflake,
    components: { APIComponent }?,
    content: string,
    edited_timestamp: string?,
    embeds: { APIEmbed },
    flags: number?,
    id: Snowflake,
    interaction: APIMessageInteraction?,
    member: APIMember?,
    mention_channels: { APIChannelMention }?,
    mention_everyone: boolean,
    mention_roles: { Snowflake },
    mentions: { APIUser },
    message_reference: APIMessageReference?,
    nonce: (string | number)?,
    pinned: boolean,
    poll: APIPoll?,
    position: number?,
    reactions: { APIReaction }?,
    referenced_message: APIMessage?,
    sticker_items: { APIStickerItem }?,
    thread: APIChannel?,
    timestamp: string,
    tts: boolean,
    type: number,
    webhook_id: Snowflake?,
}

export type APIMessageActivity = {
    party_id: string?,
    type: number,
}

export type APIApplication = {
    bot_public: boolean?,
    bot_require_code_grant: boolean?,
    cover_image: string?,
    description: string,
    flags: number?,
    guild_id: Snowflake?,
    icon: string?,
    id: Snowflake,
    install_params: {
        permissions: string,
        scopes: { string },
    }?,
    name: string,
    owner: APIUser?,
    primary_sku_id: Snowflake?,
    privacy_policy_url: string?,
    rpc_origins: { string }?,
    slug: string?,
    summary: string?,
    tags: { string }?,
    team: any?,
    terms_of_service_url: string?,
    verify_key: string,
}

export type APIAttachment = {
    content_type: string?,
    description: string?,
    duration_secs: number?,
    ephemeral: boolean?,
    filename: string,
    flags: number?,
    height: number?,
    id: Snowflake,
    proxy_url: string,
    size: number,
    url: string,
    waveform: string?,
    width: number?,
}

export type APIComponent = {
    components: { APIComponent }?,
    custom_id: string?,
    disabled: boolean?,
    emoji: APIEmoji?,
    label: string?,
    max_length: number?,
    max_values: number?,
    min_length: number?,
    min_values: number?,
    options: { APISelectOption }?,
    placeholder: string?,
    required: boolean?,
    style: number?,
    type: number,
    url: string?,
    value: string?,
}

export type APISelectOption = {
    default: boolean?,
    description: string?,
    emoji: APIEmoji?,
    label: string,
    value: string,
}

export type APIEmoji = {
    animated: boolean?,
    available: boolean?,
    id: Snowflake?,
    managed: boolean?,
    name: string?,
    require_colons: boolean?,
    roles: { Snowflake }?,
    user: APIUser?,
}

export type APIEmbed = {
    author: APIEmbedAuthor?,
    color: number?,
    description: string?,
    fields: { APIEmbedField }?,
    footer: APIEmbedFooter?,
    image: APIEmbedImage?,
    provider: APIEmbedProvider?,
    thumbnail: APIEmbedThumbnail?,
    timestamp: string?,
    title: string?,
    type: string?,
    url: string?,
    video: APIEmbedVideo?,
}

export type APIEmbedAuthor = {
    icon_url: string?,
    name: string,
    proxy_icon_url: string?,
    url: string?,
}

export type APIEmbedField = {
    inline: boolean?,
    name: string,
    value: string,
}

export type APIEmbedFooter = {
    icon_url: string?,
    proxy_icon_url: string?,
    text: string,
}

export type APIEmbedImage = {
    height: number?,
    proxy_url: string?,
    url: string,
    width: number?,
}

export type APIEmbedProvider = {
    name: string?,
    url: string?,
}

export type APIEmbedThumbnail = {
    height: number?,
    proxy_url: string?,
    url: string,
    width: number?,
}

export type APIEmbedVideo = {
    height: number?,
    proxy_url: string?,
    url: string?,
    width: number?,
}

export type APIMessageInteraction = {
    id: Snowflake,
    member: APIMember?,
    name: string,
    type: number,
    user: APIUser,
}

export type APIChannelMention = {
    guild_id: Snowflake,
    id: Snowflake,
    name: string,
    type: number,
}

export type APIMessageReference = {
    channel_id: Snowflake?,
    fail_if_not_exists: boolean?,
    guild_id: Snowflake?,
    message_id: Snowflake?,
}

export type APIPoll = {
    allow_multiselect: boolean,
    answers: { APIPollAnswer },
    expiry: string?,
    layout_type: number,
    question: APIPollMedia,
    results: APIPollResults?,
}

export type APIPollAnswer = {
    answer_id: number,
    poll_media: APIPollMedia,
}

export type APIPollMedia = {
    emoji: APIEmoji?,
    text: string?,
}

export type APIPollResults = {
    answer_counts: { APIPollAnswerCount },
    is_finalized: boolean,
}

export type APIPollAnswerCount = {
    count: number,
    id: number,
    me_voted: boolean,
}

export type APIReaction = {
    burst_colors: { string },
    count: number,
    count_details: {
        burst: number,
        normal: number,
    },
    emoji: APIEmoji,
    me: boolean,
    me_burst: boolean,
}

export type APIStickerItem = {
    format_type: number,
    id: Snowflake,
    name: string,
}

-- API Guild object
export type APIGuild = {
    afk_channel_id: Snowflake?,
    afk_timeout: number,
    application_id: Snowflake?,
    approximate_member_count: number?,
    approximate_presence_count: number?,
    banner: string?,
    channels: { APIChannel }?,
    default_message_notifications: number,
    description: string?,
    discovery_splash: string?,
    emojis: { APIEmoji },
    explicit_content_filter: number,
    features: { string },
    icon: string?,
    icon_hash: string?,
    id: Snowflake,
    joined_at: string?,
    large: boolean?,
    max_members: number?,
    max_presences: number?,
    max_stage_video_channel_users: number?,
    max_video_channel_users: number?,
    member_count: number?,
    members: { APIMember }?,
    mfa_level: number,
    name: string,
    nsfw_level: number,
    owner: boolean?,
    owner_id: Snowflake,
    permissions: string?,
    preferred_locale: string,
    premium_progress_bar_enabled: boolean,
    premium_subscription_count: number?,
    premium_tier: number,
    presences: { APIPresence }?,
    public_updates_channel_id: Snowflake?,
    roles: { APIRole },
    rules_channel_id: Snowflake?,
    safety_alerts_channel_id: Snowflake?,
    splash: string?,
    stage_instances: { APIStageInstance }?,
    stickers: { APISticker }?,
    system_channel_flags: number,
    system_channel_id: Snowflake?,
    threads: { APIChannel }?,
    unavailable: boolean?,
    vanity_url_code: string?,
    verification_level: number,
    voice_states: { APIVoiceState }?,
    welcome_screen: APIWelcomeScreen?,
    widget_channel_id: Snowflake?,
    widget_enabled: boolean?,
}

export type APIPresence = {
    activities: { APIActivity },
    client_status: {
        desktop: string?,
        mobile: string?,
        web: string?,
    },
    guild_id: Snowflake,
    status: string,
    user: APIUser,
}

export type APIActivity = {
    application_id: Snowflake?,
    assets: {
        large_image: string?,
        large_text: string?,
        small_image: string?,
        small_text: string?,
    }?,
    buttons: { string }?,
    created_at: number,
    details: string?,
    emoji: APIEmoji?,
    flags: number?,
    instance: boolean?,
    name: string,
    party: {
        id: string?,
        size: { number }?,
    }?,
    secrets: {
        join: string?,
        match: string?,
        spectate: string?,
    }?,
    state: string?,
    timestamps: {
        ["end"]: number?,
        start: number?,
    }?,
    type: number,
    url: string?,
}

export type APIStageInstance = {
    channel_id: Snowflake,
    discoverable_disabled: boolean,
    guild_id: Snowflake,
    guild_scheduled_event_id: Snowflake?,
    id: Snowflake,
    privacy_level: number,
    topic: string,
}

export type APISticker = {
    asset: string?,
    available: boolean?,
    description: string?,
    format_type: number,
    guild_id: Snowflake?,
    id: Snowflake,
    name: string,
    pack_id: Snowflake?,
    sort_value: number?,
    tags: string,
    type: number,
    user: APIUser?,
}

export type APIVoiceState = {
    channel_id: Snowflake?,
    deaf: boolean,
    guild_id: Snowflake?,
    member: APIMember?,
    mute: boolean,
    request_to_speak_timestamp: string?,
    self_deaf: boolean,
    self_mute: boolean,
    self_stream: boolean?,
    self_video: boolean,
    session_id: string,
    suppress: boolean,
    user_id: Snowflake,
}

export type APIWelcomeScreen = {
    description: string?,
    welcome_channels: { APIWelcomeScreenChannel },
}

export type APIWelcomeScreenChannel = {
    channel_id: Snowflake,
    description: string,
    emoji_id: Snowflake?,
    emoji_name: string?,
}

-- Gateway event types
export type GatewayPayload = {
    d: any?,
    op: number,
    s: number?,
    t: string?,
}

export type GatewayHelloData = {
    heartbeat_interval: number,
}

export type GatewayReadyData = {
    application: {
        flags: number,
        id: Snowflake,
    },
    guilds: { { id: Snowflake, unavailable: boolean? } },
    resume_gateway_url: string,
    session_id: string,
    shard: { number }?,
    user: APIUser,
    v: number,
}

export type GatewayIdentifyData = {
    compress: boolean?,
    intents: number,
    large_threshold: number?,
    presence: GatewayPresenceUpdateData?,
    properties: {
        browser: string,
        device: string,
        os: string,
    },
    shard: { number }?,
    token: string,
}

export type GatewayPresenceUpdateData = {
    activities: { APIActivity }?,
    afk: boolean,
    since: number?,
    status: string,
}

export type GatewayResumeData = {
    seq: number,
    session_id: string,
    token: string,
}

-- Client options
export type ClientOptions = {
    intents: number | { number },
    presence: GatewayPresenceUpdateData?,
    shards: { number }?,
}

-- Message send options
export type MessageSendOptions = {
    allowed_mentions: {
        parse: { string }?,
        replied_user: boolean?,
        roles: { Snowflake }?,
        users: { Snowflake }?,
    }?,
    attachments: { APIAttachment }?,
    components: { APIComponent }?,
    content: string?,
    embeds: { APIEmbed }?,
    flags: number?,
    message_reference: APIMessageReference?,
    nonce: (string | number)?,
    sticker_ids: { Snowflake }?,
    tts: boolean?,
}

-- Interaction types
export type APIInteraction = {
    app_permissions: string?,
    application_id: Snowflake,
    channel: APIChannel?,
    channel_id: Snowflake?,
    data: APIInteractionData?,
    entitlement_sku_ids: { Snowflake }?,
    entitlements: { APIEntitlement }?,
    guild: APIGuild?,
    guild_id: Snowflake?,
    guild_locale: string?,
    id: Snowflake,
    locale: string?,
    member: APIMember?,
    message: APIMessage?,
    token: string,
    type: number,
    user: APIUser?,
    version: number,
}

export type APIInteractionData = {
    component_type: number?,
    custom_id: string?,
    guild_id: Snowflake?,
    id: Snowflake?,
    name: string?,
    options: { APIInteractionOption }?,
    resolved: APIResolvedData?,
    target_id: Snowflake?,
    type: number?,
    values: { string }?,
}

export type APIInteractionOption = {
    focused: boolean?,
    name: string,
    options: { APIInteractionOption }?,
    type: number,
    value: (string | number | boolean)?,
}

export type APIResolvedData = {
    attachments: { [Snowflake]: APIAttachment }?,
    channels: { [Snowflake]: APIChannel }?,
    members: { [Snowflake]: APIMember }?,
    messages: { [Snowflake]: APIMessage }?,
    roles: { [Snowflake]: APIRole }?,
    users: { [Snowflake]: APIUser }?,
}

export type APIEntitlement = {
    application_id: Snowflake,
    consumed: boolean?,
    deleted: boolean,
    ends_at: string?,
    guild_id: Snowflake?,
    id: Snowflake,
    sku_id: Snowflake,
    starts_at: string?,
    type: number,
    user_id: Snowflake?,
}

-- Application command types
export type APIApplicationCommand = {
    application_id: Snowflake,
    contexts: { number }?,
    default_member_permissions: string?,
    default_permission: boolean?,
    description: string,
    description_localizations: { [string]: string }?,
    dm_permission: boolean?,
    guild_id: Snowflake?,
    id: Snowflake,
    integration_types: { number }?,
    name: string,
    name_localizations: { [string]: string }?,
    nsfw: boolean?,
    options: { APIApplicationCommandOption }?,
    type: number?,
    version: Snowflake,
}

export type APIApplicationCommandOption = {
    autocomplete: boolean?,
    channel_types: { number }?,
    choices: { APIApplicationCommandOptionChoice }?,
    description: string,
    description_localizations: { [string]: string }?,
    max_length: number?,
    max_value: number?,
    min_length: number?,
    min_value: number?,
    name: string,
    name_localizations: { [string]: string }?,
    options: { APIApplicationCommandOption }?,
    required: boolean?,
    type: number,
}

export type APIApplicationCommandOptionChoice = {
    name: string,
    name_localizations: { [string]: string }?,
    value: string | number,
}

return {}
