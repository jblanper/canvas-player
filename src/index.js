import './css/style.css';
import './css/range.css';
import createGlRenderer from './lib/renderer.js';
import setAnimation from './lib/animation.js';
import { html as h, append2body } from './lib/html.js';
import { icons } from './lib/icons.js';
import { savePng } from './lib/helper.js';

async function loadShaders () {
    const loadTxt = (url) => fetch(url).then(res => res.text()).then(text => {
        const shaderName = url.match(/\/(.+)\./)[1];
        return [shaderName,  text];
    });
    const urls = [
        'glsl/watergalaxy_color.glsl',
        'glsl/crypto_gold1.glsl',
    ];
    const glslFiles = await Promise.all(urls.map(loadTxt));

    return glslFiles;
}

function renderCanvas(canvas, fragmentShader, pixelation) {
    const renderer = createGlRenderer(canvas, fragmentShader, pixelation);
    const animation = setAnimation(_ => renderer.render());

    renderer.render();

    return [ renderer, animation ]
}

async function main () {
    const data = await loadShaders()
    const glslData = data;

    const canvas = h('canvas', { width: 500, height: 500 });
    const toggleButton = h('button.toggle', null, [ icons.play ]);
    const saveButton = h('button', null, [ icons.saveImg ]);
    const resSlider = h('input.pixelation', {
        type: 'range', max: 64,
        min: 1, step: 1, value: 1
    });
    const glslSelect = h('select', null, Array.from(glslData, x => h('option', { value: x[0] }, [ `${x[0]}` ])));
    const loadingText = h('span.loading', null, [ 'Loading...' ]);
    const divRenderer = h('div#renderer', null, [ 
        glslSelect, loadingText,
        canvas, 
        h('div.ui', null, [ toggleButton, saveButton, resSlider ])    
    ]);
    append2body(divRenderer)

    window.setTimeout(_ => {
        let [ renderer, animation ] = renderCanvas(canvas, glslData[0][1], resSlider.valueAsNumber);

        toggleButton.addEventListener('click', function(event) {
            this.classList.toggle('deactivated');
            animation.toggle();
            this.innerHTML = animation.animating ? icons.pause : icons.play;
        });

        saveButton.addEventListener('click', function(event) {
            savePng(canvas);
        })
    
        resSlider.addEventListener('input', function(event) {
            renderer.uniforms.pixelation.value = parseFloat(this.value);
            renderer.render();
        });

        glslSelect.addEventListener('change', function(event) {
            loadingText.classList.remove('hidden');
            const shaderSelected = this.value;

            window.setTimeout(_ => {
                animation.stop();
                const shader = glslData.filter(shader => shader[0] == shaderSelected)[0];
                [ renderer, animation ] = renderCanvas(canvas, shader[1], resSlider.valueAsNumber);
                loadingText.classList.add('hidden');
            }, 50);
        })

        loadingText.classList.add('hidden');
    }, 10)
}

main();
