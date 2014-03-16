use strict;
use Net::Amazon;
# This script parses a list of barcodes from an input file, queries Amazon, and exports the results to a tab-delimitted file
# It supports UPC-12, EAN-13, ISBN-10, ISBN-13
# SETUP:
# 1) ppm install Net::Amazon
# 2) Net::Amazon doesn't support EAN for the US locale, so you'll have to hack it as follows:
#    a) Copy Perl\site\lib\Net\Amazon\Validate\ItemSearch\uk\EAN.pm to ..\us folder
#    b) Modify Perl\site\lib\Net\Amazon\Validate\ItemSearch\us\EAN.pm so that all 'uk' references are replaced with 'us'
# 3) Sign-up for developer access to Amazon (it's free, easy, and fast )
#   Paste your assigned developer token and secret key into $AMAZON_TOKEN/$AMAZON_SECRET_KEY below
# USAGE:
# 1) Paste a list of barcodes below the __DATA__ line in this file
# 2) perl find_barcodes.pl 

my $AMAZON_TOKEN = 'ADDYOURAMAZONTOKENHERE';
my $AMAZON_SECRET_KEY = 'ADDYOURAMAZONSECRETKEYHERE';

# Open a connection to Amazon's Web Services
my $ua = Net::Amazon->new( token => $AMAZON_TOKEN, secret_key => $AMAZON_SECRET_KEY );
while (<DATA>)
{
    chomp;
    find_barcode($_);
}

# Looks up the given barcode in Amazon's database and writes out a record of its results
sub find_barcode
{
    my ($barcode) = @_;
    my $response;
    if (length($barcode) < 13)
    {
        $response = $ua->search(upc => $barcode);
        $response = $ua->search(isbn => $barcode) if($response->is_error()) ;
        if ($response->is_error()) # Pad with zeros to convert barcode to 13-characters
        {
            $barcode = sprintf("%013s", $barcode);
            $response = $ua->search(ean => $barcode);
            $response = $ua->search(isbn => $barcode) if ($response->is_error()); #books
        }
    }
    else
    {
        $response = $ua->search(ean => $barcode);
        $response = $ua->search(isbn => $barcode) if ($response->is_error()); #books
    }

    if($response->is_success()) 
    {
        my ($property) = $response->properties();
        my $media = $property->Media();
        $media = $property->platform() if ($media eq "Video Game");
        print join "\t", ( $barcode, $media, $property->title(), $property->ReleaseDate(), $property->OurPrice() ) , "\n";
    }
    else
    {
        print "$barcode\tERROR!!!\n"; #response->message(), "\n";
    }
}

# Paste your list of barcodes (one per line) below the __DATA__ section below
__DATA__
