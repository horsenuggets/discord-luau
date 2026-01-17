--[[

InteractionResponseType

Discord interaction response types.

--]]

local InteractionResponseType = {
    Pong = 1,
    ChannelMessageWithSource = 4,
    DeferredChannelMessageWithSource = 5,
    DeferredUpdateMessage = 6,
    UpdateMessage = 7,
    ApplicationCommandAutocompleteResult = 8,
    Modal = 9,
    PremiumRequired = 10,
    LaunchActivity = 12,
}

return table.freeze(InteractionResponseType)
