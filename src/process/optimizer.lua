Optimizer = {
}

function Optimizer.Process( ast_node, options )

    local constants_replacement = {}
    local constants_table = string.explode( options.constants_replacement, ' ' )

    for i, constant in ipairs( constants_table ) do
        local key_value = string.explode( constant, "=" )
        constants_replacement[ key_value[ 1 ] ] = key_value[ 2 ]
    end

    local constants_optimizer = ConstantsOptimizer:new( ast_node, constants_replacement )
    local shader_parameter_inliner = ShaderParameterInliner:new( ast_node, constants_optimizer )

    shader_parameter_inliner:Process()
    constants_optimizer:Process()
end