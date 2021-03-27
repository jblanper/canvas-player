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
        'glsl/marea2.glsl',
    ];
    await Promise.all(urls.map(loadTxt));

    return glslFiles;
}

function renderCanvas(canvas, fragmentShader, pixelation) {
    const renderer = createGlRenderer(canvas, fragmentShader, pixelation);
    const animation = setAnimation(_ => renderer.render(), 1000 / 24);

    renderer.render();

    return [ renderer, animation ]
}

async function main () {
    const CANVAS_WIDTH = (window.innerWidth < 450) ? window.innerWidth - 40 : 400;
    const data = await loadShaders()
    const glslData = data;
    let currentGlslCode = Object.values(glslData)[0];

    // HTML
    const canvas = h('canvas', { width: CANVAS_WIDTH, height: CANVAS_WIDTH });
    const toggleButton = h('button.toggle', null, [ icons.play ]);
    const stepButton = h('button', null, [ icons.step ]);
    const saveButton = h('button', null, [ icons.saveImg ]);
    const resSlider = h('input.pixelation', {
        type: 'range', max: 64,
        min: 1, step: 1, value: 1
    });
    const glslSelect = h('select', null, Array.from(Object.keys(glslData), x => h('option', { value: x }, [ `${x}` ])));
    const ratioSelect = h('select', null, Array.from([['1:1', 1], ['4:3', 1.33], ['16:9', 1.77]], x => h('option', { value: x[1] }, [ `${x[0]}` ])));
    const loadingText = h('span.loading.hidden', null, [ 'Loading...' ]);
    const codePanel =  h('pre', null, [ currentGlslCode ]);
    const canvasPlayer = h('div#canvas-player', null, [
        h('div.renderer', null, [ 
            h('div.row', null, [
                h('div.col.buttons', null, [ toggleButton, stepButton, saveButton ]) ,
                h('div.col.buttons', null, [ h('h1.title', null, [ "Grab my ART" ]) ]) ,
            ]),
            h('div.row.canvas-container', null, [
                canvas, loadingText
            ]),
            h('div.row', null, [ 
                h('div.col', null, [ h('label', null, [ 'Shader: ' ]), glslSelect ]),
                h('div.col', null, [ h('label', null, [ 'Aspect ratio: ' ]), ratioSelect ]),
            ]),
            h('div.row', null, [ 
                h('div.col.w100', null, [ h('label', null, [ 'Pixelation: ' ]), resSlider ]),
            ]),
            h('div.row', null, [ 
                h('div.w100.signature', null, [ 
                    'by',
                    icons.signature,
                    '·',
                    h('a', { href: 'https://twitter.com/blancoperales', target: '_blanck' }, [ 'Twitter' ]),
                    '·',
                    h('a', { href: 'https://github.com/jblanper', target: '_blanck' }, [ 'Github' ]) ,
                ]),
            ]),
        ]),
        h('div.code-panel', null, [
            codePanel
        ])
    ]);
    append2body(canvasPlayer)

    window.setTimeout(_ => {
        let [ renderer, animation ] = renderCanvas(canvas, currentGlslCode, resSlider.valueAsNumber);

        // helper function
        const redrawCanvas = (shaderName) => {
            loadingText.classList.remove('hidden');
            currentGlslCode = glslData[shaderName];
            
            window.setTimeout(_ => {
                animation.stop();
                [ renderer, animation ] = renderCanvas(canvas, currentGlslCode, resSlider.valueAsNumber);
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
            stepButton.disabled = animation.animating;
        });

        stepButton.addEventListener('click', function(event) {
            renderer.render();
        })

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
            codePanel.innerHTML = currentGlslCode;
        })
    }, 10)
}

main();
