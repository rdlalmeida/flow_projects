/**
    Main contract that takes all the Interfaces defined thus far and sets up the whole resource based process.
    
    This contract establishes all the resources from the interfaces imported but it also has to deal with an interesting limitation of Cadence. Well, it is not a proper technical limitation, but more of a "avoid this if possible" condition, which is having a Collection of Elections, while Elections are also Collections already by themselves. Though there's nothing in Cadence that prevents that, the documentation advises developers to avoid this if possible. And I wanted to because it is going to mess with idea of delegating ElectionPublic capabilities through Ballots. As such, I'm going to use this contract to come up with an automatic way to create and manage Elections without using a Collection.

    @author: Ricardo Lopes Almeida - https://github.com/rdlalmeida
**/
access(all) contract VoteBooth {
    
    // Contract constructor
    init() {}
}