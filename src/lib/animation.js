// TODO: añadir un parámetro que haga fácil la configuración por frames.
function setTimeFrameChecker (ms) {
    let lastTimestamp = 0;
    let accumulator = 0;
    const step = ms;

    return (timestamp) => {
        let deltaTime = timestamp - lastTimestamp;
        lastTimestamp = timestamp;
        accumulator += deltaTime;

        if (accumulator > step) {
           accumulator = 0;
           return true;
        }
    };
};

// TODO: añadir la opción de que solo se pase un frame
export default function setAnimation (
    loopFunc, ms = 0, stopCondition = _ => undefined
) {
    let animating = false;
    let animationID;

    const checkTimeFrame = setTimeFrameChecker(ms);

    const start = _ => {
        if (!animating) animating = true;
        animationID = window.requestAnimationFrame(loop);
    };

    const stop = _ => {
        if (animationID) {
            window.cancelAnimationFrame(animationID);
            animationID = undefined;
            animating = false;
        }
    };

    const loop = (timestamp = 0) => {
        if (stopCondition()) {
            stop();
            return;
        }
        if (checkTimeFrame(timestamp)) loopFunc(timestamp);
        start();
    };

    const toggle = _ => {
        animating = !animating

        if (animating) start();
        else stop();
    };

    return {start, stop, toggle, get animating () { return animating; }};
};