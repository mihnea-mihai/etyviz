let timeouts = {
    'validate': {
        'lang': '',
        'word': ''
    },
    'suggest': {
        'lang': '',
        'word': ''
    }
}

function validateTextInput(textInput) {
    let name = textInput.id
    fetch(`/api/validate/${name}?${name}=${textInput.value}`)
        .then(response => {
            if (response.ok) {
                textInput.className = "valid"
            }
            else {
                textInput.className = "invalid"
            }
        })
}

function initializeValidation(inputType) {
    let input = document.getElementById(inputType)
    input.addEventListener('keyup', function () {
        clearTimeout(timeouts['validate'][inputType]);
        timeouts['validate'][inputType] = setTimeout(validateTextInput, 1000, input);
    });

    input.addEventListener('keyup', function () {
        this.className = "pending"
    });
};

initializeValidation('word');
initializeValidation('lang');
