--[[

InteractionType

Discord interaction types.

--]]

const InteractionType = {
    Ping = 1,
    ApplicationCommand = 2,
    MessageComponent = 3,
    ApplicationCommandAutocomplete = 4,
    ModalSubmit = 5,
}

return table.freeze(InteractionType)
