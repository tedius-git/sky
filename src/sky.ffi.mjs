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
