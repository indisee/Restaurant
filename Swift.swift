import UIKit


//MARK: -

class Table : Comparable, CustomStringConvertible {
    
    let size:Int // number of chairs
    private var freeSeats:Int = 0
    
    init(size s:Int) {
        size = s
        freeSeats = s
    }
    
    func mayBeTaken(byGroup group:ClientsGroup) -> Bool {
        return freeSeats >= group.size
    }
    
    func taken(byGroup group:ClientsGroup) {
        freeSeats -= group.size
    }
    
    func free() {
        freeSeats = size
    }
    
    //MARK: - Comparable
    
    static func < (lhs: Table, rhs: Table) -> Bool {
        return lhs.size < rhs.size
    }
    
    static func == (lhs: Table, rhs: Table) -> Bool {
        return lhs.size == rhs.size
    }
    
    //MARK: - CustomStringConvertible
    
    var description: String {
        return "\((freeSeats != size) ? "(!)" : "")table \(freeSeats)/\(size)"
    }
}


//MARK: -

class ClientsGroup : Hashable, CustomStringConvertible {
    
    let size:Int // number of clients
    
    private var _table:Table?
    weak var table:Table? {
        get {
            return _table
        }
    }
    
    init(size s:Int) {
        size = s
    }
    
    func take(table t:Table) {
        _table = t
    }
    
    func leaveTable() {
        _table = nil
    }
    
    //MARK: - Hashable
    
    static func == (lhs: ClientsGroup, rhs: ClientsGroup) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    
    var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
    
    //MARK: - CustomStringConvertible
    
    var description: String {
        return "client \(size)"
    }
}


//MARK: -

class RestManager : CustomStringConvertible {
    
    private let tables:[Table]
    private var clientsQueue:[ClientsGroup] = [ClientsGroup]()
    
    init(tables:[Table]) {
        self.tables = tables
    }
    
    // new client(s) show up
    func onArrive(group:ClientsGroup) {
        
        let tableToSeat = findTable(forGroup: group)
        
        if let t = tableToSeat {
            t.taken(byGroup: group)
            group.take(table: t)
        } else {
            clientsQueue.append(group)
        }
    }
    
    func findTable(forGroup group:ClientsGroup) -> Table? {
        var tableToSeat:Table? = nil
        for table in tables {
            if table.mayBeTaken(byGroup: group){
                if let t = tableToSeat {
                    tableToSeat = bestOfTables(forGroup: group, table1: t, table2: table)
                } else {
                    tableToSeat = table
                }
            }
        }
        return tableToSeat
    }
    
    // client(s) leave, either served or simply abandoning the clientsQueue
    func onLeave(group:ClientsGroup) {
        if let table = group.table {
            //served
            table.free()
            group.leaveTable()
            seatNextClient(onTable: table)
        } else {
            //leave out of boredom
            clientsQueue.remove(at: clientsQueue.firstIndex(of: group)!)
        }
    }
    
    private func seatNextClient(onTable table:Table) {
        for group in clientsQueue {
            if table.mayBeTaken(byGroup: group){
                
                table.taken(byGroup: group)
                group.take(table: table)
                
                clientsQueue.remove(at: clientsQueue.firstIndex(of: group)!)
                
                break
            }
        }
    }
    
    // return table where a given client group is seated,
    // or null if it is still queuing or has already left
    func lookup(group:ClientsGroup) -> Table? {
        return group.table
    }
    
    //MARK: -
    
    private func bestOfTables(forGroup group:ClientsGroup, table1:Table, table2:Table) -> Table {
        if table1.size == group.size {
            return table1
        } else if table2.size == group.size {
            return table2
        } else {
            return min(table1, table2)
        }
    }
    
    
    //MARK: - CustomStringConvertible
    
    var description: String {
        return "\(tables)\n\(clientsQueue)"
    }
}

//tests from python version

let tables = [
Table(size: 2),
Table(size: 2),
Table(size: 3),
Table(size: 4),
Table(size: 5),
Table(size: 6),
Table(size: 6)
]

let rm = RestManager(tables: tables)
print("\(rm)\n---")

var groups = [
    ClientsGroup(size: 3),
    ClientsGroup(size: 5),
    ClientsGroup(size: 3),
    ClientsGroup(size: 5),
    ClientsGroup(size: 6),
    ClientsGroup(size: 3),
    ClientsGroup(size: 2),
    ClientsGroup(size: 4),
    ClientsGroup(size: 3),
    ClientsGroup(size: 6)
]
for g in groups {
    print("in \(g.size)")
    rm.onArrive(group: g)
    print("\(rm)")
}

print("\n---")

print("out \(groups[2])")
rm.onLeave(group: groups[2])
print("\(rm)")

print("out \(groups[8])")
rm.onLeave(group: groups[8])
print("\(rm)")

groups.append(ClientsGroup(size: 2))
print("in \(groups[10].size)")
rm.onArrive(group: groups[10])
print("\(rm)")
