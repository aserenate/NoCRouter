
filen = 'area.txt'

f = open(filen, 'r')
lines = f.readlines()
f.close()

def get_area(item):
    item = item.replace(' ', '')
    items = item.split('=')
    name = items[0]
    areas = items[1].split(',')
    area = areas[0].replace('(', '')
    ratio = areas[1]
    return name, [area, ratio]
areas = {}
for line in lines:
    if line.startswith(' '):
        line = line.replace(' ', '')
        line = line.replace('\n', '')
        items = line.split(':')
        module = items[0]
        areas[module] = {}
        items = items[1].split('),')
        for item in items[:-1]:
            name, list = get_area(item)
            areas[module][name] = list

line = ''
for module, area in areas.items():
    line += "{}\t".format(module)
    for a, list in area.items():
        line += '{}\t{}\t{}\t'.format(a, list[0], list[1])
    line += '\n'
    
f = open('result.txt', 'w')
print(line, file=f)
f.close()
    
        
    
        