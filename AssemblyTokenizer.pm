# Parrot Tokenizer in Perl

# Copyright 2002 Peter Sergeant <pete@clueball.com>

package Parrot::AssemblyTokenizer;

$VERSION = '0.01';

use strict;

sub tokenize {
	
	# Grab incoming data
	my $buffer = shift;
	
	# Create our token handler
	my $token = token_catcher();
	
	my @lines = split(/(?<=\n)/, $buffer);
	
	foreach my $line (@lines) {
	
		# First deal with preceeding white-space
		if ($line =~ s/^(\s+)(\S)/$2/) {
			$token->('whitespace', $1);
		}
	
		# Comments
		if ($line =~ /^#/) {
			$token->('comment', $line)	
	
		# Blank lines
		} elsif ($line =~ m/^\s+$/) {
			$token->('whitespace', $line)
		
		# Labels
		} elsif ($line =~ s/^(\$?[a-z0-9_]+\:)//i) {
			$token->('label', $1);
		
			# Trim any preceeding whitespace
			if ($line =~ s/^(\s+)//) {
				$token->('whitespace', $1);
			}
		
			# Check to see if we're a comment line 
			if ($line =~ m/^#/) {
				$token->('comment', $line);
		
			# So we have a function...
			} elsif ($line =~ s/^([a-z0-9_]+)//i) {
				$token->('operation', $1);
				arguments( $line, $token )
			}
		
		# operation
		} elsif ($line =~ s/^([a-z0-9_]+)//i) {
			$token->('operation', $1);
			arguments($line, $token);
		} 	
	
	}	
	
	return @{ $token->('eof') };
	
}

# Process operation arguments
sub arguments {
	
	my $line = shift;
	my $token = shift;
	
	while ($line) {
	
		# Whitespace checks
		if ($line =~ s/^(\s+)(,?)(\s*)//) {
			$token->('whitespace', $1);
			$token->('comma', ',') if $2;
			$token->('whitespace', $3) if $3;
		}
	
		return unless $line;
	
		# Comment?
		if ($line =~ m/^#/) {
			$token->('comment', $line); return;	
		
		# Quoted argument?
		} elsif ($line =~ s/^(" (?: [^"\\]+ | \\. )* ") (,?)//x) {
			$token->('double_quoted_string', $1);
			$token->('comma', ',') if $2;

		} elsif ($line =~ s/^(' (?: [^'\\]+ | \\. )* ') (,?)//x) {
			$token->('single_quoted_string', $1);
			$token->('comma', ',') if $2;		
		
		# Must be a none-quoted argument
		} elsif ($line =~ s/^(\.?\$?[\[\]+\-a-z0-9_]+)(,?)//i) {
			$token->('argument', $1);
			$token->('comma', ',') if $2;
		
		# Something has gone wrong
		} else {
			die ("*$line* -- weird\n");
		}
	}
	
}

sub token_catcher {
	
	my @tokens;
 	
 	return sub {

		my $type = shift;
		my $data = shift;
	
		if ($type eq 'eof') {
			return \@tokens
		} else {
			push(@tokens, [ $type, $data ]);
		}
		
	}
}

1;

__END__

=cut

=head1 NAME

Parrot::AssemblyTokenizer

=head1 DESCRIPTION

Tokenizes Parrot Assembly Language

=head1 SYNOPSIS

	use Parrot::AssemblyTokenizer;
	
	my @tokens = Parrot::AssemblyTokenizer::tokenize( $lines_of_pasm );
	
=head1 METHODS

=head2 tokenize

Tokenizes a scalar containing PASM ... scalar can be multiline, and it'll
do I<The Right Thing>. Returns a list of array references, that contain the
token type and the token data. Tokens can be: whitespace, comment, label,
operation, argument, comma, single_quoted_string, double_quoted_string.

=head1 BUGS AND LIMITATIONS

This is not a parser. This was written as a helper module to allow me to
do syntax highlighting of PASM - note its lack of caring about what type
an argument is. No known bugs.

=head1 AUTHOR

Peter Sergeant - pete@clueball.com

=head1 LICENSE / COPYRIGHT

Copyright 2002 Peter Sergeant. 

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

