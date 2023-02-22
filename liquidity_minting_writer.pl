use strict;
use warnings;
use DBD::Pg qw(:pg_types);
use JSON;

my $json = JSON->new->canonical;

my $minting_contract;

sub liquidity_minting_prepare
{
    my $args = shift;
    
    if( not defined($args->{'minting_contract'}) )
    {
        print STDERR "Error: liquidity_minting_writer.pl requires --parg minting_contract=XXX\n";
        exit(1);
    }

    $minting_contract = $args->{'minting_contract'};

    my $dbh = $main::db->{'dbh'};

    $main::db->{'current_rewards_ins'} =
        $dbh->prepare('INSERT INTO CURRENT_REWARDS (account, currency, precision, reward_snapshot) ' .
                      'VALUES (?,?,?,?)');

    $main::db->{'current_rewards_del'} =
        $dbh->prepare('DELETE FROM CURRENT_REWARDS WHERE account=? AND currency=? AND precision=?');

    $main::db->{'rewards_history_ins'} =
        $dbh->prepare('INSERT INTO REWARDS_HISTORY (block_num, account, currency, precision, reward_snapshot) ' .
                      'VALUES (?,?,?,?,?)');

    $main::db->{'rewards_history_del'} =
        $dbh->prepare('DELETE FROM REWARDS_HISTORY WHERE block_num=? AND account=? AND currency=? AND precision=?');
    
    printf STDERR ("liquidity_minting_writer.pl prepared\n");
}



sub liquidity_minting_check_kvo
{
    my $kvo = shift;

    if( $kvo->{'code'} eq $minting_contract and $kvo->{'table'} eq 'rewards' )
    {
        return 1;
    }
    return 0;
}


sub liquidity_minting_row
{
    my $added = shift;
    my $kvo = shift;
    my $block_num = shift;

    if( $kvo->{'code'} eq $minting_contract )
    {
        if( $kvo->{'table'} eq 'rewards' and $kvo->{'scope'} eq $minting_contract )
        {
            my $account = $kvo->{'value'}{'account'};

            foreach my $entry (@{$kvo->{'value'}{'stakes'}})
            {
                my($precision, $symbol) = split(/,/, $entry->{'key'}{'sym'});
                                                               
                if( $added )
                {
                    my $reward_snapshot = $json->encode($entry->{'value'});
                    $main::db->{'current_rewards_ins'}->execute($account, $symbol, $precision, $reward_snapshot);
                    $main::db->{'rewards_history_ins'}->execute($block_num, $account, $symbol, $precision, $reward_snapshot);
                }
                else
                {
                    $main::db->{'current_rewards_del'}->execute($account, $symbol, $precision);
                    $main::db->{'rewards_history_del'}->execute($block_num, $account, $symbol, $precision);
                }
            }
        }
    }
}




push(@main::prepare_hooks, \&liquidity_minting_prepare);
push(@main::check_kvo_hooks, \&liquidity_minting_check_kvo);
push(@main::row_hooks, \&liquidity_minting_row);

1;
