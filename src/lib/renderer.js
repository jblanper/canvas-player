import * as THREE from 'three';

export default function createGlRenderer(canvas, fragmentShader, pixelation = 1.0) {
    const scene = new THREE.Scene();
    const camera = new THREE.Camera();
    camera.position.z = 1;
    const geometry = new THREE.PlaneBufferGeometry(2, 2);

    const uniforms = {
        time: { type: "f", value: 1.0 },
        resolution: { type: "v2", value: new THREE.Vector2() },
        pixelation: { type: "f", value: parseFloat(pixelation) }
    };
    
    const material = new THREE.ShaderMaterial({
        uniforms: uniforms,
        fragmentShader
    });
    
    const mesh = new THREE.Mesh(geometry, material);
    scene.add(mesh);
    
    const renderer = new THREE.WebGLRenderer({ 
        canvas ,
        preserveDrawingBuffer: true
    });

    uniforms.resolution.value.set(
        renderer.domElement.clientWidth, 
        renderer.domElement.clientHeight
    );

    const render = () => {
        // resizeRendererToDisplaySize(renderer);
        uniforms.time.value += .05;
        renderer.render(scene, camera);
    }

    return { render, uniforms, domElement: renderer.domElement };
}

function resizeRendererToDisplaySize(renderer) {
    // https://threejsfundamentals.org/threejs/lessons/threejs-shadertoy.html
    const canvas = renderer.domElement;
    const width = canvas.clientWidth;
    const height = canvas.clientHeight;
    const needResize = canvas.width !== width || canvas.height !== height;

    if (needResize) {
      renderer.setSize(width, height, false);
    }
    
    return needResize;
}