const sha256 = require("js-sha256");
const gzip = require("gzip-js");
const Tar = require("tar-js");

import formSpec from "./form.json";
import "./style.css";

// utility function to create DOM nodes
function mknod({
  name,
  text,
  attrs,
  children
}={}){
  const n = document.createElement(name);
  if (text) {
    n.appendChild(document.createTextNode(text));
  }
  if (attrs) {
    for (const k in attrs) {
      let v = attrs[k];
      if (v) {
        n.setAttribute(k, v);
      }
    }
  }
  if (children) {
    for (const child of children) {
      n.appendChild(child);
    }
  }
  return n;
}

// function to build form based on JSON
function createForm() {
  const formNode = mknod({name: "form"});

  for (const group of formSpec.formgroups) {
    // groups of fields
    const fieldsetNode = mknod({
      name: "fieldset",
      children: [
        mknod({
          name: "legend",
          text: group.label,
        })
      ]
    });
    formNode.appendChild(fieldsetNode);

    for (const input of group.inputs) {
      if (input.type == "CHOCO") {
        // insert software selector
        // TODO make this dynamically expanding
        for (let i = 0; i < 8; i++) {
          fieldsetNode.appendChild(mknod({
            name: "p",
            children: [
              mknod({
                name: "input",
                attrs: {
                  type: "text",
                  name: "choco_pkg[]",
                  placeholder: "Package Name"
                }
              }),
              mknod({
                name: "input",
                attrs: {
                  type: "text",
                  name: "choco_version[]",
                  placeholder: "Package Version"
                }
              })
            ]
          }));
        }
        continue;
      }

      // individual inputs
      const pNode = mknod({name: "p"});
      fieldsetNode.appendChild(pNode);

      const labelNode = mknod({
        name: "label",
        text: input.label,
        attrs: {
          "for": input.name
        }
      });

      if (input.type != "checkbox") {
        pNode.appendChild(labelNode);
      }

      if (!input.type || input.type == "text") {
        // text input
        pNode.appendChild(mknod({
          name: "input",
          attrs: {
            name: input.name,
            id: input.name,
            type: "text",
            value: input.default ? input.default : ""
          }
        }));

      } else if (input.type == "checkbox") {
        // checkbox
        pNode.appendChild(mknod({
          name: "input",
          attrs: {
            name: input.name,
            id: input.name,
            type: "checkbox",
            value: input.value,
            checked: input.default !== false
          }
        }));
        labelNode.classList.add("checkbox");
        pNode.appendChild(labelNode);

      } else if (input.type == "select") {
        // dropdown
        const selectNode = mknod({
          name: "select",
          attrs: {
            name: input.name,
            id: input.name
          }
        });
        pNode.appendChild(selectNode);

        let options = [];
        if (input.options == "TIMEZONE") {
          options = formSpec.timezones;
        } else if (input.options == "LOCALE") {
          options = formSpec.locales;
        }

        for (const option of options) {
          selectNode.appendChild(mknod({
            name: "option",
            text: option,
            attrs: {
              selected: option === input.default
            }
          }));
        }
      }
    }
  }

  const downloadButtonNode = mknod({
    name: "input",
    attrs: {
      type: "button",
      value: "Download",
    }
  });
  downloadButtonNode.addEventListener("click", build)
  formNode.appendChild(downloadButtonNode);

  document.querySelector("main").appendChild(formNode);
}

async function loadFiles() {
  window.ovf_tpl = await (await (await fetch("./ovf.tpl")).blob()).arrayBuffer();
  window.vmdk_tpl = await (await new Response(
    (await (await fetch("./disk.vmdk.gz")).blob())
    .stream()
    .pipeThrough(new DecompressionStream("gzip"))
  ).blob()).arrayBuffer();

  let vmdk_manifest = new TextDecoder("utf-8").decode(await (await (await fetch("./disk.vmdk.manifest")).blob()).arrayBuffer());
  window.vmdk_tpl_offset = parseInt(vmdk_manifest.split("\n")[2].split(" ")[0]);
}

window.addEventListener("DOMContentLoaded", async () => {
  createForm();
  await loadFiles();
});

// function to read the form and build the image
function build() {
  var cfg = {};
  cfg["PS_PRIVACY"] = 0;
  cfg["PS_USABILITY"] = 0;
  cfg["PS_HARDENING"] = 0;
  cfg["PS_BLOAT"] = 0;

  var vm = {};
  var choco_pkgs = [];
  var choco_vers = [];
  var choco = [];

  document.querySelectorAll("form input, form select").forEach(n => {
    if(!n.name) {
      return;
    }
    if(n.name.startsWith("vm_")) {
      vm[n.name.toUpperCase()] = n.value;
    }
    if(n.name.startsWith("iso_")) {
      if(n.name == "iso_wim_index") {
        cfg["WIM_INDEX"] = n.value;
      } else {
        cfg[n.name.toUpperCase()] = n.value;
      }
    }
    if(n.name.startsWith("ua_")) {
      if(n.type == "checkbox") {
        cfg[n.name.toUpperCase()] = n.checked ? "true" : "false";
      } else {
        cfg[n.name.toUpperCase()] = n.value;
      }
    }
    if(n.name.startsWith("usab_") && n.checked) {
      cfg["PS_USABILITY"] |= parseInt(n.value);
    }
    if(n.name.startsWith("priv_") && n.checked) {
      cfg["PS_PRIVACY"] |= parseInt(n.value);
    }
    if(n.name.startsWith("bloat_") && n.checked) {
      cfg["PS_BLOAT"] |= parseInt(n.value);
    }
    if(n.name.startsWith("hard_") && n.checked) {
      cfg["PS_HARDENING"] |= parseInt(n.value);
    }
    if(n.name.startsWith("choco_pkg")) {
      choco_pkgs.push(n.value);
    }
    if(n.name.startsWith("choco_version")) {
      choco_vers.push(n.value);
    }
  });

  for(var i = 0; i < choco_pkgs.length; i++) {
    if(choco_pkgs[i].trim()) {
      choco.push(choco_pkgs[i].trim());
      choco.push(choco_vers[i].trim());
    }
  }
  cfg["PS_CHOCO"] = choco.join("|");

  var cfg_lines = [];
  cfg_lines.push("#!/bin/sh");
  Object.entries(cfg).forEach(([k, v]) => {
    cfg_lines.push("export " + k + "=" + JSON.stringify(v));
  });
  cfg_lines = cfg_lines.join("\n");
  console.log(cfg_lines);

  // TODO replace with browser gzip implementation
  var cfg_gz = gzip.zip(cfg_lines);

  var cfg_packed = new Uint8Array(128 + cfg_gz.length + 16);
  cfg_packed.set(
    new TextEncoder().encode(
      [
        "cfg",
        "128",
        cfg_gz.length.toString(),
        sha256(cfg_gz),
        ""
      ]
      .join("\n")
    ),
    0
  );
  cfg_packed.set(cfg_gz, 128);

  var vmdk = new Uint8Array(window.vmdk_tpl.byteLength);
  vmdk.set(new Uint8Array(window.vmdk_tpl));
  vmdk.set(cfg_packed, window.vmdk_tpl_offset);

  var ovf = new TextDecoder("utf-8").decode(window.ovf_tpl);
  Object.entries(vm).forEach(([k, v]) => {
    ovf = ovf.replaceAll("${" + k + "}", v);
  });

  var tape = new Tar();
  tape.append("winvm.ovf", ovf);
  var ova = tape.append("disk.vmdk", vmdk);

  var a;
  a = document.createElement("a");
  var url = window.URL.createObjectURL(new Blob([ova], {type: "application/octet-stream"}));
  a.href = url;
  a.download = "winvm.ova";
  a.style.display = "none";
  document.body.appendChild(a);
  a.click();
  a.remove();
  setTimeout(() => { window.URL.revokeObjectURL(url); }, 1000);
}
