filename = "./FinnishSymbolNames.csv"
separator = ";"

content = {}
categories = []

with open(filename, "r") as f:
    for category in f.readline().split(separator):
        category = category.strip()
        content[category] = []
        categories.append(category)
    line = f.readline()
    while line:
        entries = line.split(separator)
        for i in range(len(categories)):
            entry = 
            content[categories[i]].append(entries[i])
        line = f.readline()
f.close()
    

