#!/usr/bin/perl

# Copyright (2025) W. Paterson
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
 
# Acknowledgements
# Leslie D. Doyle for your kindness, inspiration, and guidance 

use strict;
use warnings;
use Parse::RecDescent;
use Data::Dumper;

# Enable parse tree - this creates [@item] for each rule
$::RD_AUTOACTION = q { [@item] };

my $grammar = q{
    program: statement(s) run_stmt(?) eof
    
    statement: data_step | proc_step | print_stmt
    
    data_step: 'data' identifier options(?) ';' 
               data_body(s?)
    
    proc_step: 'proc' proc_name dataset(?) options(?) ';'
               proc_body(s?)
    
    run_stmt: 'run' ';'
    
    print_stmt: 'print' identifier ';'
    
    # Fixed: Only specific data step statements - NO catch-all rules
    data_body: assignment | conditional | output_stmt | keep_stmt | drop_stmt | label_stmt
    
    assignment: identifier '=' expression ';'
    
    output_stmt: 'output' dataset_list(?) condition(?) ';'
    
    conditional: 'if' condition 'then' statement_block 
                 ('else' statement_block)(?)
    
    # Common data step statements
    keep_stmt: 'keep' identifier(s) ';'
    drop_stmt: 'drop' identifier(s) ';'  
    label_stmt: 'label' identifier '=' /[^;]+/ ';'
    
    proc_body: proc_option
    
    # Lexical elements
    identifier: /[a-zA-Z_][a-zA-Z0-9_]*/
    proc_name: /[a-zA-Z][a-zA-Z0-9]*/
    dataset: identifier
    expression: /[^;]+/
    condition: /[^;]+/
    dataset_list: identifier(s /\s+/)
    options: /\([^)]*\)/
    
    statement_block: /[^;]+;/
    proc_option: /[a-zA-Z_][a-zA-Z0-9_]*\s*=\s*[^;]+;/
    
    eof: /^\s*\Z/
};

# Enable debugging and tracing (commented out for cleaner output)
# $::RD_TRACE = 1;  # Show what rules are being tried
$::RD_ERRORS = 1; # Show detailed error messages
# $::RD_WARN = 1;   # Show warnings

my $parser = Parse::RecDescent->new($grammar);
if (!defined $parser) {
    die "Parser creation failed!";
}
print "Parser created successfully\n";

# Read filenames from STDIN - accepts one or MORE files on one line separated by spaces
# Files should be located in the same directory as this Perl script
# Usage: perl script.pl < filelist.txt where filelist.txt contains: file1 file2 file3 file4
my $input_line = <STDIN>;
if (!defined $input_line) {
    die "No input provided!\n";
}
chomp $input_line;
my @filenames = split /\s+/, $input_line;

foreach my $filename (@filenames) {
    next unless $filename; # Skip empty entries
    
    print "\n" . "="x60 . "\n";
    print "=== $filename ===\n";
    print "="x60 . "\n";
    
    # Declare $fh in the proper scope - before the open() call
    my $fh;
    if (!open($fh, '<', $filename)) {
        print "Error: Cannot open file '$filename': $!\n";
        next;
    }
    
    my $file_content = do { local $/; <$fh> };
    close $fh;
    
    # Make sure content ends with newline for eof rule
    $file_content .= "\n" unless $file_content =~ /\n$/;
    
    # Parse the file content
    print "File content to parse:\n";
    print "'" . $file_content . "'\n";
    print "Length: " . length($file_content) . " characters\n";
    
    my $result = $parser->program($file_content);
    if (defined $result) {
        print "Parse successful!\n";
        print Dumper($result);
    } else {
        print "Parse failed!\n";
        # Remove the error() call that's causing the crash
        print "Parser could not match the input syntax\n";
    }
}

1;
