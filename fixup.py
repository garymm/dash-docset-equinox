import os
import sys
from concurrent.futures import ThreadPoolExecutor
from bs4 import BeautifulSoup
import re


def fixup_html(file_path):
    with open(file_path, "r", encoding="utf-8") as file:
        soup = BeautifulSoup(file, "html.parser")

    for a_tag in soup.find_all("a", href=True):
        href = a_tag["href"]
        if href.startswith(("http://", "https://", "#")):
            continue
        if href.endswith("/") or not re.search(r"\.[a-zA-Z0-9]+$", href.split("/")[-1]):
            a_tag["href"] = href.rstrip("/") + "/index.html"

    with open(file_path, "w", encoding="utf-8") as file:
        file.write(str(soup))


def process_docset(docset_path):
    html_files = []
    for root, _, files in os.walk(docset_path):
        for file in files:
            if file.endswith(".html"):
                html_files.append(os.path.join(root, file))

    with ThreadPoolExecutor() as executor:
        executor.map(fixup_html, html_files)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python fixup.py <docset_path>")
        sys.exit(1)

    docset_path = sys.argv[1]
    process_docset(docset_path)
