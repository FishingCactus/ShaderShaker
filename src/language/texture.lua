function Texture2D( name )

    _G[ name ] = { type = "texture2D", node = "Texture", name = name };
end

function Texture( name )

    _G[ name ] = { type = "texture", node = "Texture", name = name };
end

function Sampler( parameter )

    _G[ parameter.name ] = { type = "sampler", node = "Sampler", name = parameter.name, parameters = parameter }
end