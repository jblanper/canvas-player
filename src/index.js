import './style.css';
import createGlRenderer from './lib/renderer.js';
import setAnimation from './lib/animation.js';
import { html as h, append2body } from './lib/html.js';

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
    const toggleButton = h('button.toggle', null, ['play']);
    const resSelect = h('select', null, Array.from([1,2,4,8,16,32,64], x => h('option', { value: x }, [ `${x}` ])));
    const glslSelect = h('select', null, Array.from(glslData, x => h('option', { value: x[0] }, [ `${x[0]}` ])));
    const loadingText = h('span.loading', null, [ 'Loading...' ]);
    const divRenderer = h('div#renderer', null, [ 
        canvas, 
        h('div.ui', null, [ toggleButton, resSelect, glslSelect, loadingText ])    
    ]);
    append2body(divRenderer)
    divRenderer.style.width = canvas.clientWidth + 'px';

    window.setTimeout(_ => {
        let [ renderer, animation ] = renderCanvas(canvas, glslData[0][1], resSelect.value);

        toggleButton.addEventListener('click', function(event) {
            this.classList.toggle('deactivated');
            animation.toggle();
            this.innerHTML = animation.animating ? 'pause' : 'play';
        });
    
        resSelect.addEventListener('change', function(event) {
            renderer.uniforms.pixelation.value = parseFloat(this.value);
            renderer.render();
        });

        glslSelect.addEventListener('change', function(event) {
            loadingText.style.display = 'inline-block';
            const shaderSelected = this.value;

            window.setTimeout(_ => {
                animation.stop();
                const shader = glslData.filter(shader => shader[0] == shaderSelected)[0];
                [ renderer, animation ] = renderCanvas(canvas, shader[1], resSelect.value);
                loadingText.style.display = 'none';
            }, 50);
        })

        loadingText.style.display = 'none';
    }, 10)
}

main();
