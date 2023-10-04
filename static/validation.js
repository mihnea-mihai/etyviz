let timeouts = {};
langInput = document.getElementById('lang');

function clickDropdown() {
    inp = this.parentElement.parentElement
        .getElementsByTagName('input')[0];
    inp.value = this.innerText;
    inp.className = 'valid';
    this.parentElement.innerHTML = '';
}

async function fetchApi(input, apiType) {
    let apiName = 'lang';
    let langInfo = '';
    if (input.name == 'word') {
        apiName = 'word';
        langInfo = `&lang=${langInput.value}`;
    }
    return fetch(
        `/api/${apiType}/${apiName}?${apiName}=${input.value}${langInfo}`
    );
}

async function validateInput(input) {
    const response = await fetchApi(input, 'validate');
    if (response.ok) {
        input.className = 'valid';
    } else {
        input.className = 'invalid';
    }
}

async function suggestInput(input) {
    const response = await fetchApi(input, 'suggest');
    const txt = await response.text();
    let dropdown = input.parentElement
        .getElementsByClassName('dropdown')[0]
    dropdown.innerHTML = txt
    for (const span of dropdown.getElementsByTagName('span')) {
        span.addEventListener('click', clickDropdown);
    }
}

function suggestInputDelayed() {
    clearTimeout(timeouts[`suggest/${this.name}`]);
    timeouts[`suggest/${this.name}`] =
        setTimeout(suggestInput, 500, this);
}

function validateInputDelayed() {
    clearTimeout(timeouts[`validate/${this.name}`]);
    timeouts[`validate/${this.name}`] =
        setTimeout(validateInput, 500, this);
}

function addValidation(inputId) {
    let input = document.getElementById(inputId);
    input.addEventListener('keyup', validateInputDelayed);
    input.addEventListener('keyup', suggestInputDelayed);
}

for (const elemId of ['lang', 'word', 'filter-lang']) {
    addValidation(elemId);
}
