Optimizer = {
}

function Optimizer.Process( ast_node, options )
    local constants_optimizer = ConstantsOptimizer:new( ast_node, options.constants_replacement )
    local shader_parameter_inliner = ShaderParameterInliner:new( ast_node, constants_optimizer )

    shader_parameter_inliner:Process()
    constants_optimizer:Process()
end