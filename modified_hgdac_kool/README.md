How to use:
1. Create a new virtual environment
2. Install requirements.txt in the virtual environment
3. Execute the following:
cd baselines/hgs_vrptw
make all
(Use mingw32-make all if on windows, make sure to install mingw32 before hand)
cd ../..

4. Convert JSON to solomon by:
python convert_to_solomon.py --input _JsonInput_ --output output.txt

5. Run the following: 
python controller.py --instance output.txt --epoch_tlim 20 --static -- run.bat
On Linux/Mac:
python controller.py --instance output.txt --epoch_tlim 20 --static -- ./run.sh

This code is based on: https://github.com/ortec/euro-neurips-vrp-2022-quickstart and on the following research work:

* [1] [Vidal et al., Operations Research, 60(3), 611-624, (2012)](https://www.cirrelt.ca/DocumentsTravail/CIRRELT-2011-05.pdf) 
* [2] [Vidal, Computers & Operations Research, 140, 105643, (2022)](https://arxiv.org/pdf/2012.10384.pdf) 
* [3] [Vidal et al., Computers & Operations Research, 40(1), 475-489 (2013)](https://www.cirrelt.ca/DocumentsTravail/CIRRELT-2011-61.pdf) 
* [4] [Vidal et al., European Journal of Operational Research, 234(3), 658-673 (2014)](https://www.cirrelt.ca/DocumentsTravail/CIRRELT-2013-22.pdf) 
* [5] [Kool et al., DIMACS Competition Technical Report (2022)](https://wouterkool.github.io/pdf/paper-kool-hgs-vrptw.pdf)


# Acknowledgements
* Original [HGS-CVRP](https://github.com/vidalt/HGS-CVRP) code (awesome!): Thibaut Vidal
* Additional contributions to HGS-CVRP, resulting in HGS-VRPTW (DIMACS VRPTW winning solver): Wouter Kool, Joep Olde Juninck, Ernst Roos, Kamiel Cornelissen, Pim Agterberg, Jelke van Hoorn, Thomas Visser
* Quickstart repository: Wouter Kool, Danilo Numeroso, Abdo Abouelrous, Robbert Reijnen
* Codalab submission system: Wouter Kool, Tom Catshoek
