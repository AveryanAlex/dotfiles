{
  hm.home.file.".local/share/jupyter/nbconvert/templates/latex/index.tex.j2".text = ''
    ((=- Default to the notebook output style -=))
    ((*- if not cell_style is defined -*))
        ((* set cell_style = 'style_jupyter.tex.j2' *))
    ((*- endif -*))

    ((=- Inherit from the specified cell style. -=))
    ((* extends cell_style *))


    %===============================================================================
    % Latex Article
    %===============================================================================

    ((*- block docclass -*))
    \documentclass[11pt]{article}
    ((*- endblock docclass -*))


    ((*- block packages -*))
    ((( super() )))
    \setmainfont{DejaVu Serif}
    \setsansfont{DejaVu Sans}
    \setmonofont{DejaVu Sans Mono}

    \usepackage{polyglossia}
    \setdefaultlanguage{russian}
    \setotherlanguages{english}

    ((*- endblock packages -*))
  '';
}
