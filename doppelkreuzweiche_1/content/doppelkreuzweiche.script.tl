local builtin = ug_require "::/gui/main/builtin.lua" as Builtin
local react = ug_require "::/gui/main/react.lua" as React
local view_manager_util = ug_require "::/gui/entity_window/view_manager_util.tl" as ViewManagerUtil
local original = ug_require "::/gui/entity_window/double_slip_switch.tl" as Recipe<IEntityWindowParam>

local doppelkreuzweiche : any = {}

-- Same as the original recipe, but Yes/No as ToggleButtonGroup instead of ComboBox.
local DoubleSlipSwitchButtons = react.RegisterRecipe("DoppelkreuzweicheButtons", function(param : IEntityWindowParam) : TreeNodeId
	-- traffic light configuration: untouched original
	if view_manager_util.baseNodeCanConfigTrafficLight(param.keyEntity) then
		return react.CallOriginalRecipe(original, param)
	end

	local baseNodeConfig : Engine.Component.BaseNodeConfig = api.engine.getComponent(param.keyEntity, api.type.ComponentType.BASE_NODE_CONFIG)
	local isThere : boolean = (baseNodeConfig ~= nil) and baseNodeConfig.doubleSlipSwitch or false
	local state = react.useState(isThere) as ReactStateT<boolean>

	return builtin.BoxLayout {
		orientation = builtin.type.Orientation.Horizontal,
		children = {
			builtin.ToggleButtonGroup {
				buttons = {
					{ content = builtin.TextView { meta = { class = "font-scale-body" }, text = _("Yes") } },
					{ content = builtin.TextView { meta = { class = "font-scale-body" }, text = _("No") } },
				},
				selected = state:old() and 1 or 2,
				onValueChange = function(index : integer)
					local value = index == 1
					state:set(value)
					local proposal = api.engine.util.proposal.createDoubleSlipSwitchProposal(param.keyEntity, value)
					local command = api.cmd.makeWorldBuildProposalCmd(proposal, nil, false, true)
					api.cmd.sendCommand(command, function(cmdData : WorldBuildProposalCommandData, success : boolean)
						if success then
							api.gui.construction.provideDustWheneverPossible(cmdData.proposal, cmdData.resultProposalData)
						end
					end)
				end,
			},
		},
	}
end)

doppelkreuzweiche.doReplace = function(replacementApi : ReactReplacementApi)
	local ok, err = pcall(replacementApi.ReplaceRecipe, original, DoubleSlipSwitchButtons)
	if not ok then
		log.error("DOPPELKREUZWEICHE " .. tostring(err))
	end
end

return doppelkreuzweiche
