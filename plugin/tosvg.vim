" Vim plugin for converting a syntax highlighted file to SVG
" (C) 2021 Philipp Marek; LGPLv2.1.

if exists('g:loaded_2svg_plugin')
    finish
endif
let g:loaded_2svg_plugin = 'y'


" How much dy for each line? 1.0 looks too dense for me.
let g:to_svg_line_spacing=1.1

" Depends on the font used, sadly; 0.8 did work for me
" 0 means to insert spaces, which should align nicely
let g:to_svg_char_spacing=0 

let g:to_svg_font_size=12

let g:to_svg_background='transparent'
let g:to_svg_font_family='monospace'

if !&cp && !exists(":TOSvg") && has("user_commands")
    command -range=% -nargs=? -bar TOSvg :call Convert2SVG(<line1>, <line2>, '<args>')
endif

function! TOSvgStyle(id, attr, name)
    let val = synIDattr(a:id, a:attr, 'gui')
    return (val == v:null) ? '' : (' ' . a:name . ': ' . val . ';')
endfunction

function! Convert2SVG(l1, l2, fn)
    let pre_style_data = []
    let data = []
    let l = a:l1
    let vert_pos = 1
    let styles = {}
    let max_width = 0

    call add(pre_style_data, '<?xml version="1.0" standalone="no"?>')
    call add(pre_style_data, '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">')
    let svg_index = len(pre_style_data)
    call add(pre_style_data, '<svg>') " gets replaced

    call add(pre_style_data, '<style type="text/css">')
    call add(pre_style_data, printf(".body { color: black; font-family: %s; font-size: %dpx; white-space: pre; }", g:to_svg_font_family, g:to_svg_font_size))
    call add(pre_style_data, printf(".body > rect { color: none; fill: %s }", g:to_svg_background))
    call add(data, '</style>')
    call add(data, '<g class="body">')
    call add(data, '<rect x="0" y="0" width="100%" height="100%"/>')

    while l <= a:l2

        let line = getline(l)
        let max_col = col([l,'$'])

        if max_col > max_width
            let max_width = max_col
        endif

        let old_syn = -1

        let svg_text = [ printf('<text y="%.2fem" data-row="%d">', vert_pos*g:to_svg_line_spacing, l)]
        let vert_pos = vert_pos + 1

        let col = 1
        let spaces = 0
        while col < max_col
            let new_syn = synIDtrans(synID(l, col, 1))
            let byte_pos = col([l, col-1])
            let c_char = line[byte_pos]

            if c_char == "\t" || c_char == " "
                let spaces = spaces + 1
                let col = col + 1
                continue
            endif

            let syn_different = (new_syn != old_syn)

            " virtcol()
            if old_syn >= 0 && (syn_different || spaces)
                call add(svg_text, '</tspan>')
            endif

            "if new_syn == 0
            "    " EOL
            "    break
            "endif

            if syn_different || spaces
                let old_syn = new_syn

                " Adding spaces like this makes it depend on the used font!
                if g:to_svg_char_spacing > 0
                    let spc_txt = (spaces > 0) ? printf('dx="%.1fem" ',  spaces * g:to_svg_char_spacing) : ''
                    "data-col="%d" col
                    call add(svg_text, printf('<tspan %s class="s%d">', spc_txt, new_syn))
                else
                    call add(svg_text, printf('<tspan class="s%d">%*s', new_syn, spaces, ""))
                endif
                let spaces = 0
            endif

            let styles[new_syn] = {}

            if c_char == "<"
                let c_char = "&lt;"
            elseif c_char == ">"
                let c_char = "&gt;"
            elseif c_char == "&"
                let c_char = "&amp;"
            endif
            call add(svg_text, c_char)
            let col = col + 1
        endwhile

        if len(svg_text) > 1
            call add(svg_text, '</tspan>')
        endif

        call add(svg_text, '</text>')
        call add(data, join(svg_text, ""))
        let l = l + 1
    endwhile

    let style_text = []
    for id in keys(styles)
        let style = '.s' . id . ' { '

        let style = style . TOSvgStyle(id, 'fg', 'fill')
        "let style = style . TOSvgStyle(id, 'bg', 'background-color')
        let style = style . '}'
        let style = style . ' /* ' . synIDattr(id, 'name') . ' */'
        call add(style_text, style)
    endfor

    call add(data, '</g>')
    call add(data, '</svg>')

    let w_px = max_width * g:to_svg_font_size * 0.75
    let h_px = l * g:to_svg_font_size * g:to_svg_line_spacing
    let pre_style_data[svg_index] = printf('<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 %.0f %.0f">', w_px, h_px)

    let a_fn = trim(expand(a:fn)) " Expand so that '%:r' works
    let ffn = ((a_fn > "") ? a_fn : expand('%:r') . '.' . localtime()) . '.svg'

    let win_id = bufwinid(ffn) 
    if win_id == -1
        execute ':new ' . ffn
    else
        call win_gotoid(win_id)
    endif
    call deletebufline('', 1, '$')
    call append(0, extend(extend(pre_style_data, style_text), data))
endfunction

" vim: sw=4 sts=4 et
