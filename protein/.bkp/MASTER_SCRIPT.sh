# so the idea here is to create a script that runs through 
# the whole of a simple simulation for the user. This will
# then be wrapped for Galaxy.

# The commands and .mdp files are (for now) based on Justin
# Lemkul's GROMACS tutorial at 
# http://www.bevanlab.biochem.vt.edu/Pages/Personal/justin/gmx-tutorials/lysozyme/

#################
### VARIABLES ###
#################

pdb_input='1AKI.pdb'
# $pdb_output=1AKI_processed.gro
topol='topol.top'
posres='posre.itp'
h2o='spce'
ff='oplsaa'
ignore_h='no'
box_d='1.0'
box_type='cubic'
ions_mdp='ions.mdp'
minim_mdp='minim.mdp'
nvt_mdp='nvt.mdp'
npt_mdp='npt.mdp'
md_mdp='md.mdp'


##################
##### SCRIPT #####
##################

# generate topology
gmx pdb2gmx -f $pdb_input -o processed.gro -p $topol -i $posres -water $h2o -ff $ff -${ignore_h}ignh

# generate box
gmx editconf -f processed.gro -o newbox.gro -c -d $box_d -bt $box_type

# solvate box
gmx solvate -cp newbox.gro -cs spc216.gro -o solv.gro -p $topol

# neutralise charge in box
gmx grompp -f $ions_mdp -c solv.gro -p $topol -o ions.tpr -maxwarn 1
echo 'SOL' | gmx genion -s ions.tpr -o solv_ions.gro -p $topol -pname NA -nname CL -neutral

# energy minimisation
gmx grompp -f $minim_mdp -c solv_ions.gro -p $topol -o em.tpr
gmx mdrun -v -deffnm em

# equilibration - constant volume
gmx grompp -f $nvt_mdp -c em.gro -r em.gro -p $topol -o nvt.tpr
gmx mdrun -v -deffnm nvt

# equilibration - constant pressure
gmx grompp -f $npt_mdp -c nvt.gro -r em.gro -t nvt.cpt -p $topol -o npt.tpr
gmx mdrun -v -deffnm npt

# run simulation
gmx grompp -f $md_mdp -c npt.gro -t npt.cpt -p $topol -o md_0_1.tpr
gmx mdrun -v -deffnm md_0_1