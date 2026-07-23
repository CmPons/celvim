" Vim syntax file
" Language: GLSL (OpenGL Shading Language)

if exists("b:current_syntax")
  finish
endif

" Keywords
syntax keyword glslConditional if else switch case default
syntax keyword glslRepeat for while do
syntax keyword glslStatement break continue return discard
syntax keyword glslStorageClass const in out inout uniform attribute varying
syntax keyword glslStorageClass centroid flat smooth noperspective
syntax keyword glslStorageClass layout patch sample
syntax keyword glslStorageClass buffer shared coherent volatile restrict readonly writeonly
syntax keyword glslStorageClass precise invariant
syntax keyword glslStructure struct

" Precision qualifiers
syntax keyword glslPrecision lowp mediump highp precision

" Types
syntax keyword glslType void bool int uint float double
syntax keyword glslType vec2 vec3 vec4 dvec2 dvec3 dvec4
syntax keyword glslType bvec2 bvec3 bvec4 ivec2 ivec3 ivec4 uvec2 uvec3 uvec4
syntax keyword glslType mat2 mat3 mat4 mat2x2 mat2x3 mat2x4
syntax keyword glslType mat3x2 mat3x3 mat3x4 mat4x2 mat4x3 mat4x4
syntax keyword glslType dmat2 dmat3 dmat4 dmat2x2 dmat2x3 dmat2x4
syntax keyword glslType dmat3x2 dmat3x3 dmat3x4 dmat4x2 dmat4x3 dmat4x4
syntax keyword glslType sampler1D sampler2D sampler3D samplerCube
syntax keyword glslType sampler1DShadow sampler2DShadow samplerCubeShadow
syntax keyword glslType sampler1DArray sampler2DArray
syntax keyword glslType sampler1DArrayShadow sampler2DArrayShadow
syntax keyword glslType samplerBuffer sampler2DMS sampler2DMSArray
syntax keyword glslType isampler1D isampler2D isampler3D isamplerCube
syntax keyword glslType isampler1DArray isampler2DArray
syntax keyword glslType isamplerBuffer isampler2DMS isampler2DMSArray
syntax keyword glslType usampler1D usampler2D usampler3D usamplerCube
syntax keyword glslType usampler1DArray usampler2DArray
syntax keyword glslType usamplerBuffer usampler2DMS usampler2DMSArray
syntax keyword glslType image1D image2D image3D imageCube
syntax keyword glslType image1DArray image2DArray
syntax keyword glslType imageBuffer image2DMS image2DMSArray
syntax keyword glslType iimage1D iimage2D iimage3D iimageCube
syntax keyword glslType iimage1DArray iimage2DArray
syntax keyword glslType iimageBuffer iimage2DMS iimage2DMSArray
syntax keyword glslType uimage1D uimage2D uimage3D uimageCube
syntax keyword glslType uimage1DArray uimage2DArray
syntax keyword glslType uimageBuffer uimage2DMS uimage2DMSArray
syntax keyword glslType atomic_uint

" Built-in constants
syntax keyword glslBoolean true false

" Built-in variables
syntax keyword glslBuiltin gl_Position gl_PointSize gl_ClipDistance gl_CullDistance
syntax keyword glslBuiltin gl_VertexID gl_InstanceID gl_FragCoord gl_FrontFacing
syntax keyword glslBuiltin gl_PointCoord gl_SampleID gl_SamplePosition
syntax keyword glslBuiltin gl_FragDepth gl_SampleMask gl_SampleMaskIn
syntax keyword glslBuiltin gl_PrimitiveID gl_InvocationID gl_Layer gl_ViewportIndex
syntax keyword glslBuiltin gl_PatchVerticesIn gl_TessLevelOuter gl_TessLevelInner
syntax keyword glslBuiltin gl_TessCoord
syntax keyword glslBuiltin gl_NumWorkGroups gl_WorkGroupSize gl_WorkGroupID
syntax keyword glslBuiltin gl_LocalInvocationID gl_GlobalInvocationID gl_LocalInvocationIndex

" Preprocessor
syntax region glslPreProc start="^\s*#\s*" end="$" keepend
syntax match glslPreProcDir /^\s*#\s*\(define\|undef\|if\|ifdef\|ifndef\|else\|elif\|endif\|error\|pragma\|extension\|version\|line\|include\)/

" Numbers
syntax match glslNumber /\<[0-9]\+[uU]\?\>/
syntax match glslFloat /\<[0-9]\+\.[0-9]*\([eE][+-]\?[0-9]\+\)\?[fFlL]\?\>/
syntax match glslFloat /\<\.[0-9]\+\([eE][+-]\?[0-9]\+\)\?[fFlL]\?\>/
syntax match glslFloat /\<[0-9]\+[eE][+-]\?[0-9]\+[fFlL]\?\>/
syntax match glslNumber /\<0[xX][0-9a-fA-F]\+[uU]\?\>/

" Comments
syntax region glslComment start="/\*" end="\*/" contains=glslTodo
syntax match glslComment "//.*$" contains=glslTodo
syntax keyword glslTodo contained TODO FIXME XXX NOTE HACK

" Strings (for preprocessor)
syntax region glslString start=/"/ skip=/\\"/ end=/"/

" Highlighting
highlight default link glslConditional Conditional
highlight default link glslRepeat Repeat
highlight default link glslStatement Statement
highlight default link glslStorageClass StorageClass
highlight default link glslStructure Structure
highlight default link glslPrecision StorageClass
highlight default link glslType Type
highlight default link glslBoolean Boolean
highlight default link glslBuiltin Special
highlight default link glslPreProc PreProc
highlight default link glslPreProcDir PreProc
highlight default link glslNumber Number
highlight default link glslFloat Float
highlight default link glslComment Comment
highlight default link glslTodo Todo
highlight default link glslString String

let b:current_syntax = "glsl"
