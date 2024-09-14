import re
import xml.etree.ElementTree as ET


import argparse

parser = argparse.ArgumentParser(description="Update XML file for project release")
parser.add_argument("--tag", help="Release tag")
parser.add_argument("--proj_name", help="Project name")
args = parser.parse_args()

TAG = args.tag
PROJ_NAME = args.proj_name

# Assuming TAG and PROJ_NAME are defined earlier in the script
xml_file = f"{PROJ_NAME}.xml"

# Read the XML file
tree = ET.parse(xml_file)
root = tree.getroot()

# Get the current version
current_version = root.find(".//version").text

# Extract version from TAG
version = TAG.replace(f"{PROJ_NAME}-", "")
version = version[1:] if version.startswith("v") else version

# Update the version
version_elem = root.find(".//version")
version_elem.text = version

# Update the URL
url_elem = root.find(".//url")
url_elem.text = re.sub(rf"/v[^/]*/{PROJ_NAME}-v[^.]*", f"/{TAG}/{TAG}", url_elem.text)

# Move the current version to other-versions
other_versions = root.find(".//other-versions")
new_version = ET.SubElement(other_versions, "version")
name = ET.SubElement(new_version, "name")
name.text = current_version

# Write the updated XML back to the file
tree.write(xml_file, encoding="utf-8", xml_declaration=True)

print("XML file updated successfully.")
