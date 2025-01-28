import { menubutton, popover, box, button, label, image } from "astal/gtk3";
import { Gtk } from "astal/gtk3";

export default function PowerMenu() {
  return (
    <menubutton
      halign={Gtk.Align.END}
      popover={
        <popover>
          <box orientation={Gtk.Orientation.VERTICAL}>
            <button onClicked={() => print("Lock")}>
              <label label="Lock" />
            </button>
            <button onClicked={() => print("Reboot")}>
              <label label="Reboot" />
            </button>
            <button onClicked={() => print("Hibernate")}>
              <label label="Hibernate" />
            </button>
            <button onClicked={() => print("Power Off")}>
              <label label="Power Off" />
            </button>
          </box>
        </popover>
      }
    >
      <image iconName="system-shutdown-symbolic" pixelSize={24} />
    </menubutton>
  );
}
