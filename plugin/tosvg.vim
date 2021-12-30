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


if !&cp && !exists(":TOSvg") && has("user_commands")
    command -range=% -bar TOSvg :call Convert2SVG(<line1>, <line2>)
endif

function! TOSvgStyle(id, attr, name)
    let val = synIDattr(a:id, a:attr, 'gui')
    return (val == v:null) ? '' : (' ' . a:name . ': ' . val . ';')
endfunction

function! Convert2SVG(l1, l2)
    let l = a:l1
    let vert_pos = 1
    let syn_ids = {}
    let svg_texts = []
    let height = a:l2 - a:l1
    let width = 200

    while l <= a:l2
        let line = getline(l)
        let old_syn = -1

        let text = [ printf('<text y="%.2fem" data-row="%d">', vert_pos*g:to_svg_line_spacing, l)]
        let vert_pos = vert_pos + 1

        let col = 1
        let spaces = 0
        while col < width
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
                call add(text, '</tspan>')
            endif

            if new_syn == 0
                " EOL
                break
            endif

            if syn_different || spaces
                let old_syn = new_syn

                " Adding spaces like this makes it depend on the used font!
                if g:to_svg_char_spacing > 0
                    let spc_txt = (spaces > 0) ? printf('dx="%.1fem" ',  spaces * g:to_svg_char_spacing) : ''
                    "data-col="%d" col
                    call add(text, printf('<tspan %s class="s%d">', spc_txt, new_syn))
                else
                    call add(text, printf('<tspan class="s%d">%*s', new_syn, spaces, ""))
                endif
                let spaces = 0
            endif

            let syn_ids[new_syn] = {}

            if c_char == "<"
                let c_char = "&lt;"
            elseif c_char == ">"
                let c_char = "&gt;"
            elseif c_char == "&"
                let c_char = "&amp;"
            endif
            call add(text, c_char)
            let col = col + 1
        endwhile

        if col == width
            call add(text, '</tspan>')
        endif

        call add(text, '</text>')
        call add(svg_texts, join(text, ""))
        let l = l + 1
    endwhile

    let svg_styles = []
    for id in keys(syn_ids)
        let css = '.s' . id . ' { '

        let fg = TOSvgStyle(id, 'fg', 'fill')
        if fg != ' fill: ;' && fg != '' && fg != ' fill: none;'
            let css = css . fg
        endif
        let bg = TOSvgStyle(id, 'bg', 'background-color')
        if bg != ' background-color: ;' && bg != '' && bg != ' background-color: none;'
            let css = css . bg
        endif
        let css = css . '}'
        let css = css . ' /* ' . synIDattr(id, 'name') . ' */'
        call add(svg_styles, css)
    endfor

    let fg = synIDattr(hlID("Normal"), "fg")
    let bg = synIDattr(hlID("Normal"), "bg")
    let svg = []
    call add(svg, '<?xml version="1.0" standalone="no"?>')
    call add(svg, '<!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 1.1//EN" "http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd">')
    call add(svg, printf('<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="fill: %s; background-color: %s; font-family: monospace; white-space: pre;" viewBox="0 0 %d %d">', fg, bg, width, height))
    call add(svg, '<style type="text/css">')
    let svg = extend(svg, svg_styles)
    call add(svg, '</style>')
    call add(svg, '<g class="body">')
    let svg = extend(svg, svg_texts)
    call add(svg, '</g>')
    call add(svg, '</svg>')

    :execute ':new /tmp/' . expand('%:t') . '.' . localtime() . '.svg'
    call append(0, svg)
endfunction

" vim: sw=4 sts=4 et
