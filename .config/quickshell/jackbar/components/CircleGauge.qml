import QtQuick
import "." as C

Item {
    id: root
    property int size: 28
    property real value: 0.0
    property int thickness: 4
    property color color: "#69a"
    property color trackColor: C.Theme.track
    property string label: ""
    property alias hovered: mouse.containsMouse

    width: size
    height: size

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative
        renderTarget: Canvas.Image
        onPaint: {
            var ctx = getContext("2d");
            var w = width;
            var h = height;
            ctx.reset();
            ctx.clearRect(0, 0, w, h);
            var cx = w / 2;
            var cy = h / 2;
            var r = Math.min(w, h) / 2 - root.thickness / 2;
            ctx.lineWidth = root.thickness;
            ctx.lineCap = "round";
            ctx.strokeStyle = root.trackColor;
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2);
            ctx.stroke();

            var start = -Math.PI / 2;
            var end = start + Math.PI * 2 * Math.max(0, Math.min(1, root.value));
            ctx.strokeStyle = root.color;
            ctx.beginPath();
            ctx.arc(cx, cy, r, start, end);
            ctx.stroke();
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.label
        color: C.Theme.text
        font.pixelSize: Math.round(root.size * 0.42) - 4
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
    }

    onValueChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()
    onThicknessChanged: canvas.requestPaint()
    onSizeChanged: canvas.requestPaint()
}
