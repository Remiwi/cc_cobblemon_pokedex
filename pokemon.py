import requests
from bs4 import BeautifulSoup
import json


class PokemonData:
    def __init__(self, number, species):
        self.number = number
        self.species = species
    
    def __repr__(self):
        return str(self.number) + ";" + str(self.species)



def main():
    response = requests.get("https://wiki.cobblemon.com/index.php/Pok%C3%A9mon/Spawning")
    if response.status_code != 200:
        print("Status code:", response.status_code)
        return
    soup = BeautifulSoup(response.content, "html.parser")

    cobblemons = {}
    for i, entries in enumerate(soup.find_all("tbody")):
        for entry in entries.find_all("tr"):
            data = []
            for col in entry.find_all("td"):
                data.append(col.text)
            
            if len(data) == 0 or data[0] == "":
                continue
            
            num, name = data[0], data[1]
            if i == 4:
                num, name = data[1], data[2]
            if num not in cobblemons and num[0] in "0123456789":
                cobblemons[num] = PokemonData(num, name)

    file = open("cobblemons.txt", "w", encoding="utf-8")
    text = "\n".join([repr(cobblemons[c]) for c in cobblemons])
    file.write(text)
    file.close()


        

main()