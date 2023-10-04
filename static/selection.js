var filterLang = document.querySelector('div.filter-lang');
var filterLangInput = document.querySelector('input[name="filter-lang"');

function parseSelected() {
    var selected = document.querySelector('input[type="radio"]:checked');
    if (selected.value == 'history') {
        filterLang.hidden = true;
        filterLangInput.disabled = true;
        filterLangInput.required = false;
    } else {
        filterLang.hidden = false;
        filterLangInput.disabled = false;
        filterLangInput.required = true;
    }
}

document.querySelectorAll('input[type="radio"');
for (const radio of document.querySelectorAll('input[type="radio"')) {
    radio.addEventListener('change', parseSelected);
}

