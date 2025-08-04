export function clear_timeout(timerId) {
    clearTimeout(timerId);
}

export function set_interval(delay, callback) {
    return setInterval(callback, delay);
}

export function clear_interval(timerId) {
    clearInterval(timerId);
}

export function get_window_width() {
    return window.innerWidth;
}

export function get_window_height() {
    return window.innerHeight;
}

export function setup_mouse_listener(dispatch) {
    const handleMouseMove = (event) => {
        const rect = event.target.getBoundingClientRect();
        const x = event.clientX - rect.left;
        const y = event.clientY - rect.top;

        dispatch(x, y);
    };

    document.addEventListener('mousemove', handleMouseMove);

    return () => {
        document.removeEventListener('mousemove', handleMouseMove);
    };
}
