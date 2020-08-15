import crypto.sha256
import time
import json

struct Block {
    data      string
    timestamp u64 = time.now().unix_time_milli()
    prev_hash string
    mut:
    hash      string
    nonce     int
}

fn (self Block) calc_hash() string { // FIXME: try making self mut
    // hash everything except the hash itself
    tmp := Block{data: self.data, timestamp: self.timestamp,
                 prev_hash: self.prev_hash, nonce: self.nonce}
    return sha256.sum(json.encode(tmp).bytes()).hex()
}

fn (mut self Block) mine(difficulty int) {
    // proof-of-work
    zeros := "0".repeat(difficulty)
    for !self.hash.starts_with(zeros) {
        self.nonce++
        self.hash = self.calc_hash()
    }
}

fn (self Block) valid() bool {
    return self.hash == self.calc_hash()
}

struct Blockchain {
    difficulty int
    mut:
    chain      []Block
}

fn (mut self Blockchain) add_genesis_block() {
    mut b := Block{ data: "genesis" }
    b.mine(self.difficulty)
    self.chain << b
}

fn (mut self Blockchain) add_block(data string) {
    if self.chain.len == 0 {
        self.add_genesis_block()
    }
    mut b := Block{
        data:      data,
        prev_hash: self.chain[self.chain.len - 1].hash
    }
    b.mine(self.difficulty)
    self.chain << b
}

fn (self Blockchain) invalid_details() string {
    for i in 1..self.chain.len {
        curr := self.chain[i]
        prev := self.chain[i - 1]
        if !curr.valid() {
            return "Rehashing failed at $i"
        }
        if curr.prev_hash != prev.hash {
            return "Previous hash of $i is not the same as in ${i - 1}"
        }
    }
    return "None"
}

fn (self Blockchain) valid() bool {
    return self.invalid_details() == "None"
}

fn demo_good() Blockchain {
    mut c := Blockchain{3}
    println(">> Adding data")
    c.add_block("Test1")
    c.add_block("Test2")
    c.add_block("Test3")
    return c
}

fn demo_bad() Blockchain {
    mut c := demo_good()
    println(">> Changing Test2")
    c.chain[2].nonce++
    return c
}

fn main() {
    c := demo_good()
    //c := demo_bad()
    println(c.chain)
    println("invalid details: " + c.invalid_details())
}
