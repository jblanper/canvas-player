import './css/style.css';
import './css/range.css';
import createGlRenderer from './lib/renderer.js';
import setAnimation from './lib/animation.js';
import { html as h, append2body } from './lib/html.js';
import { icons } from './lib/icons.js';
import { savePng } from './lib/helper.js';

async function loadShaders () {
    let glslFiles = {};

    const loadTxt = (url) => fetch(url).then(res => res.text()).then(text => {
        const shaderName = url.match(/\/(.+)\./)[1];
        glslFiles[shaderName] = text;
    });
    const urls = [
        'glsl/watergalaxy_color.glsl',
        'glsl/crypto_gold1.glsl',
    ];
    await Promise.all(urls.map(loadTxt));

    return glslFiles;
}

function renderCanvas(canvas, fragmentShader, pixelation) {
    const renderer = createGlRenderer(canvas, fragmentShader, pixelation);
    const animation = setAnimation(_ => renderer.render());

    renderer.render();

    return [ renderer, animation ]
}

async function main () {
    const CANVAS_WIDTH = 500;
    const data = await loadShaders()
    const glslData = data;

    const canvas = h('canvas', { width: 500, height: 500 });
    const toggleButton = h('button.toggle', null, [ icons.play ]);
    const saveButton = h('button', null, [ icons.saveImg ]);
    const resSlider = h('input.pixelation', {
        type: 'range', max: 64,
        min: 1, step: 1, value: 1
    });
    const glslSelect = h('select', null, Array.from(Object.keys(glslData), x => h('option', { value: x }, [ `${x}` ])));
    const ratioSelect = h('select.vtop', null, Array.from([['1:1', 1], ['4:3', 1.33], ['16:9', 1.77]], x => h('option', { value: x[1] }, [ `${x[0]}` ])));
    const loadingText = h('span.loading', null, [ 'Loading...' ]);
    const divRenderer = h('div#renderer', null, [ 
        glslSelect, loadingText,
        canvas, 
        h('div.ui', null, [ resSlider, toggleButton, saveButton, ratioSelect ])    
    ]);
    append2body(divRenderer)

    window.setTimeout(_ => {
        let [ renderer, animation ] = renderCanvas(canvas, Object.values(glslData)[0], resSlider.valueAsNumber);

        const redrawCanvas = (shaderName, callback = null) => {
            loadingText.classList.remove('hidden');
            
            window.setTimeout(_ => {
                animation.stop();
                if (callback) callback();
                [ renderer, animation ] = renderCanvas(canvas, glslData[shaderName], resSlider.valueAsNumber);
                loadingText.classList.add('hidden');
            }, 50);
        }

        // Event listeners

        toggleButton.addEventListener('click', function(event) {
            this.classList.toggle('deactivated');
            animation.toggle();
            this.innerHTML = animation.animating ? icons.pause : icons.play;
            ratioSelect.disabled = animation.animating;
            glslSelect.disabled = animation.animating;
        });

        saveButton.addEventListener('click', function(event) {
            savePng(canvas);
        })
    
        resSlider.addEventListener('input', function(event) {
            renderer.uniforms.pixelation.value = parseFloat(this.value);
            renderer.render();
        });

        ratioSelect.addEventListener('change', function(event) {
            canvas.height = CANVAS_WIDTH / this.value;
            redrawCanvas(glslSelect.value);
        });

        glslSelect.addEventListener('change', function(event) {
            redrawCanvas(this.value);
        })

        loadingText.classList.add('hidden');
    }, 10)
}

main();
