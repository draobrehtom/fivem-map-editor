window.addEventListener('message', (event) => {
    const item = event.data;
    if (item == undefined || item.action != 'notification') { return; }

    let content = $(`
        <div class="notification">
            <span style="color: var(--foxx-bright);">` + (item.icon ? '<i class="fa fa-' + item.icon + '"></i> ' : '') + `` + item.title + `</span>
            <p>` + item.message + `</p>
        </div>
    `);

    $('#notifications').prepend(content);

    setTimeout(() => {
        content.remove();
    }, 5000)
});