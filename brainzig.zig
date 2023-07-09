const std = @import("std");

const Instruction = enum(u8) {
    Increment = '+', // VLINC_XXXXXXXXXXXXXXXX
    Decrement = '-', // VLDEC_XXXXXXXXXXXXXXXX
    DataPointerIncrement = '>', // DPINC_XXXXXXXXXXXXXXXX
    DataPointerDecrement = '<', // DPDEC_XXXXXXXXXXXXXXXX
    JumpIfZero = '[', // JZ_XXXXXXXXXXXXXXXX
    JumpIfNotZero = ']', // JNZ_XXXXXXXXXXXXXXXX
    Output = '.', // OUT_XXXXXXXXXXXXXXXX
    Input = ',', // IN_XXXXXXXXXXXXXXXX
};

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const stdin = std.io.getStdIn().reader();

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var allocator = arena.allocator();

    var input_buffer = std.ArrayList(u8).init(allocator);
    defer input_buffer.deinit();

    try stdout.print("Welcome to brainzig, a brainfuck interpreter written in Zig programming language!\n", .{});

    try stdout.print("Input:", .{});
    // user inputs Brainfuck code
    try stdin.streamUntilDelimiter(input_buffer.writer(), '\n', 512);

    //const wasd = [_]u8{0};
    // remove windows \r
    //try input_buffer.replaceRange(input_buffer.items.len - 1, 1, wasd[0..]);

    //_ = std.mem.trimRight(u8, input_buffer.items, "\n\r");

    var memory = [_]u8{0} ** 30_000;

    var memory_begin: usize = 0;
    // if I use comptime knowned values, data_pointer will
    // not be a slice, but an array pointer
    // https://ziglang.org/documentation/master/#Slices
    var data_pointer = memory[memory_begin..memory.len];

    for (input_buffer.items, 0..) |instruction, index| {
        var foo = try GenerateInstructionSymbol(&input_buffer.items[index], allocator);

        try stdout.print("{s}\n", .{foo});

        try InterpretInstruction(@as(Instruction, @enumFromInt(instruction)), &data_pointer, memory.len);
    }

    try stdout.print("Input: {s}{d}\n", .{ input_buffer.items, @as(i32, data_pointer[0]) });
}

fn GenerateInstructionSymbol(instruction: *const u8, allocator: std.mem.Allocator) ![]u8 {
    var symbol = std.ArrayList(u8).init(allocator);
    defer symbol.deinit(); // not needed since returning with .toOwnedSlice

    switch (instruction.*) {
        @intFromEnum(Instruction.Increment) => {
            try symbol.appendSlice("VLINC_");
        },
        @intFromEnum(Instruction.Decrement) => {
            try symbol.appendSlice("VLDEC_");
        },
        @intFromEnum(Instruction.DataPointerIncrement) => {
            try symbol.appendSlice("DPDEC_");
        },
        @intFromEnum(Instruction.DataPointerDecrement) => {
            try symbol.appendSlice("DPDEC_");
        },
        else => {},
    }

    try symbol.writer().print("{X}", .{@intFromPtr(instruction)});
    return try symbol.toOwnedSlice();
}

fn InterpretInstruction(instruction: Instruction, data_pointer: *[]u8, memory_size: usize) !void {
    switch (instruction) {
        .Increment => {
            data_pointer.*[0] = data_pointer.*[0] + 1;
        },
        Instruction.Decrement => {
            data_pointer.*[0] = data_pointer.*[0] - 1;
        },
        Instruction.DataPointerIncrement => {
            std.debug.assert(data_pointer.len - 1 >= 0);
            data_pointer.ptr = data_pointer.ptr + 1;
            data_pointer.len = data_pointer.len - 1;
        },
        Instruction.DataPointerDecrement => {
            std.debug.assert(data_pointer.len + 1 <= memory_size);
            data_pointer.ptr = data_pointer.ptr - 1;
            data_pointer.len = data_pointer.len + 1;
        },
        Instruction.Input => {},
        Instruction.Output => {},
        Instruction.JumpIfZero => {
            switch (data_pointer.*[0]) {
                0 => {
                    // jump instruction pointer to end of scope
                },
                else => {
                    // move instruction pointer forward
                },
            }
        },
        Instruction.JumpIfNotZero => {
            switch (data_pointer.*[0]) {
                0 => {
                    // move instruction pointer forward
                },
                else => {
                    // jump instruction pointer to start of scope
                },
            }
        },
    }
}
