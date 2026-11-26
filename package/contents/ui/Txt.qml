import QtQuick

// One text primitive so every label in the widget shares the same scale:
// 11 / 12 / 13 / 14 / 17 (ratio ~1.12), one sans family, one mono family for data.
Text {
    property string kind: "body"     // title | head | body | small | tiny | mono | monoSm
    property bool strong: false
    property bool tnum: false
    readonly property bool isMono: kind === "mono" || kind === "monoSm"
    font.family: isMono ? Theme.mono : Theme.sans
    font.pixelSize: Theme.fs({ title: 17, head: 14, body: 13, small: 12, tiny: 11, mono: 12, monoSm: 11 }[kind])
    font.weight: strong ? Font.DemiBold : Font.Normal
    font.features: (tnum || isMono) ? { "tnum": 1 } : ({})
    color: Theme.tx
    textFormat: Text.PlainText
    renderType: Text.NativeRendering
}
