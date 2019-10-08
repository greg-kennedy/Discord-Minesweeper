#!/usr/bin/env perl
use strict;
use warnings;

use WebService::Discord::Webhook;

# Discord Minesweeper
#  Greg Kennedy 2019

##############################################################################
# CONFIGURATION
use constant {

  # board size
  WIDTH  => 10,
  HEIGHT => 10,

  # number of mines
  MINES => 10,

  # Discord WebHook URL
  URL =>
    'https://discordapp.com/api/webhooks/223704706495545344/3d89bb7572e0fb30d8128367b3b1b44fecd1726de135cbe28a41f8b2f777c372ba2939e72279b94526ff5d1bd4358d65cf11'
};

##############################################################################
# CONSTANTS

# empty and mine square values
use constant {
  EMPTY => 0,
  MINE  => 9,
};

# emoji to place for each value
use constant EMOJI => (
  "\x{2B1C}",     # large white square
  "1\x{20E3}",    # 1 keycap
  "2\x{20E3}",    # 2 keycap
  "3\x{20E3}",
  "4\x{20E3}",
  "5\x{20E3}",
  "6\x{20E3}",
  "7\x{20E3}",
  "8\x{20E3}",
  "\x{1F4A3}",    # bomb
);

# zero-width joiner (space character)
use constant ZWJ => "\x{200B}";

##############################################################################
# CODE

# Empty array to hold our board
my @minefield;

# pass 1: clear board
#  (not really necessary, but it makes code cleaner later)
for ( my $y = 0; $y < HEIGHT; $y++ ) {
  for ( my $x = 0; $x < WIDTH; $x++ ) {
    $minefield[$y][$x] = EMPTY;
  }
}

# pass 2: place mines
my $mines_placed = 0;
while ( $mines_placed < MINES ) {

  # pick a random square
  my $x = int( rand WIDTH );
  my $y = int( rand HEIGHT );

  # if this square is empty, place a mine
  if ( $minefield[$y][$x] == EMPTY ) {
    $minefield[$y][$x] = MINE;
    $mines_placed++;
  }
}

# pass 3: calculate numbers for each empty square
for ( my $y = 0; $y < HEIGHT; $y++ ) {
  for ( my $x = 0; $x < WIDTH; $x++ ) {

    # skip mines
    next if ( $minefield[$y][$x] == MINE );

    # check surrounding squares with a small loop
    my $mines_adjacent = 0;
    for ( my $j = $y - 1; $j <= $y + 1; $j++ ) {
      next if ( $j < 0 || $j >= HEIGHT );
      for ( my $i = $x - 1; $i <= $x + 1; $i++ ) {
        next if ( $i < 0 || $i >= WIDTH );

        # do not check self
        #next if ($i == $x && $y == $j);

        # add 1 to running count if a mine is found
        if ( $minefield[$j][$i] == MINE ) {
          $mines_adjacent++;
        }
      }
    }

    # set computed result back to the board
    $minefield[$y][$x] = $mines_adjacent;
  }
}

# last step: choose a starting spot to reveal
my ($revealed_x, $revealed_y);
do {
  # pick a random x, y, and loop if the square
  #  is not empty
  $revealed_x = int( rand WIDTH );
  $revealed_y = int( rand HEIGHT );
} while ( $minefield[$revealed_y][$revealed_x] != EMPTY );

# DONE WITH GENERATION.

# compose message
my $post = '';

for ( my $y = 0; $y < HEIGHT; $y++ ) {
  for ( my $x = 0; $x < WIDTH; $x++ ) {

    # Add a "zero-width joiner" between adjacent cells
    if ( $x > 0 ) {
      $post .= ZWJ;
    }

    if ( $x == $revealed_x && $y == $revealed_y ) {
      # This is the revealed square.
      $post .= (EMOJI)[ $minefield[$y][$x] ];
    } else {
      # Spoiler tags surround this square
      $post .= '||' . (EMOJI)[ $minefield[$y][$x] ] . '||';
    }
  }

  # a newline after each row.
  $post .= "\n";
}

# MAKE POST
#  Create the webhook object
my $webhook = WebService::Discord::Webhook->new(URL);

#  Post the message
$webhook->execute($post);
