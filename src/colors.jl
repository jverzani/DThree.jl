## need to use Color.jl to generate this. Here we use R's gray.colors



fifty_shades_of_gray = ["#4D4D4D", "#535353", "#5A5A5A", "#5F5F5F", "#656565", "#6A6A6A", "#6F6F6F", "#737373", "#777777", "#7C7C7C", "#808080", "#838383", "#878787", "#8B8B8B", "#8E8E8E", "#929292", "#959595", "#989898", "#9B9B9B", "#9E9E9E", "#A1A1A1", "#A4A4A4", "#A7A7A7", "#AAAAAA", "#ADADAD", "#AFAFAF", "#B2B2B2", "#B5B5B5", "#B7B7B7", "#BABABA", "#BCBCBC", "#BFBFBF", "#C1C1C1", "#C3C3C3", "#C6C6C6", "#C8C8C8", "#CACACA", "#CDCDCD", "#CFCFCF", "#D1D1D1", "#D3D3D3", "#D5D5D5", "#D7D7D7", "#D9D9D9", "#DCDCDC", "#DEDEDE", "#E0E0E0", "#E2E2E2", "#E4E4E4", "#E6E6E6"]

## cycle through colors
fifty_shades(i::Int) = fifty_shades_of_gray[mod1(1 + (i-1)*11, length(fifty_shades_of_gray))]


shapes = ["circle", "cross", "triangle-up", "triangle-down", "diamond", "square"]
