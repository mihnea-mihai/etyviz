let word_input = document.getElementById('word')

function clickDropdown() {
    inp = this.parentElement.parentElement
        .getElementsByTagName('input')[0];
    inp.value = this.innerText;
    inp.className = 'valid';
    this.parentElement.innerHTML = '';
}

let word_suggest_timeout;
word_input.addEventListener('keyup', function () {
    clearTimeout(word_suggest_timeout);
    word_suggest_timeout = setTimeout(function () {
        let part_word = word_input.value
        fetch('/api/suggest/word?part_word=' + part_word)
            .then(response => {
                return response.json();
            }).then(words => {
                dropdown = word_input.parentElement.getElementsByClassName('dropdown')[0]
                dropdown.innerHTML = '';
                words.forEach(word => {
                    word_elem = document.createElement('span')
                    word_elem.innerHTML = word;
                    word_elem.addEventListener('click', clickDropdown)
                    dropdown.appendChild(word_elem);
                    console.log(word)
                });
            })
    }, 500, word_input);
});


