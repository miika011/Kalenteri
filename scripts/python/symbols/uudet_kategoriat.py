filepath = r"C:\Users\miika\design\XD libraries\mulberry-symbols\kategoriat.csv"
separator = ";"
list_separator = "&"

kategoriat = set()
lineNumber = 0
with open(filepath, "r") as f:
    f.readline()
    while line := f.readline():
        lineNumber += 1
        if line.strip() == "":
            continue
        entries = line.split(separator)
        print(f"{str(lineNumber)}: {entries}")
        old_categories, new_categories = entries
        old_categories = old_categories.strip()
        new_categories = new_categories.strip()
        for c in new_categories.split(list_separator):
            kategoriat.add(c.strip())
        
