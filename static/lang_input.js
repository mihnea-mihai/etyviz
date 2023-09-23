let lang_input = document.getElementById('lang')

function clickDropdown() {
    inp = this.parentElement.parentElement
        .getElementsByTagName('input')[0];
    inp.value = this.innerText;
    inp.className = 'valid';
    this.parentElement.innerHTML = '';
}

let lang_suggest_timeout;
lang_input.addEventListener('keyup', function () {
    clearTimeout(lang_suggest_timeout);
    lang_suggest_timeout = setTimeout(function () {
        let part_lang = lang_input.value
        fetch('/api/suggest/lang?part_lang=' + part_lang)
            .then(response => {
                return response.json();
            }).then(langs => {
                dropdown = lang_input.parentElement.getElementsByClassName('dropdown')[0]
                dropdown.innerHTML = '';
                langs.forEach(lang => {
                    lang_elem = document.createElement('span')
                    lang_elem.innerHTML = lang;
                    lang_elem.addEventListener('click', clickDropdown)
                    dropdown.appendChild(lang_elem);
                    console.log(lang)
                });
            })
    }, 500, lang_input);
});


