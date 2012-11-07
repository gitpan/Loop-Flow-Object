package Loop::Flow::Object;

use 5.006;
use strict;
use warnings;

use POSIX ':sys_wait_h'; # для waitpid -1, WNOHANG;

=encoding utf8

=head1 ПРИВЕТСТВИЕ SALUTE

Доброго всем! Доброго здоровья! Доброго духа!

Hello all! Nice health! Good thinks!

=head1 NAME

Loop::Flow::Object - запуск цикла для объекта с контролем и переключением ветвления (fork), выполнение кода в указанных методах объекта.

Loop::Flow::Object - looping code of one object with forking on/off. Simple switch and count of forks.

Executing code, control count and exit from loop by the object methods.


=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

    package Some::My::Module;
    
    sub new {
        my $class = shift;
        ...
    
    }
    sub one {# main code in loop
        my $self = shift;
        my @data = @_;
        ...
    }
    
    sub data {# data for main code in loop
        my $self = shift;
        my $count = shift;
        ...
    }
    
    sub end {# end hook
        my $self = shift;
        ....
    }
    
    package main;
    
    use Loop::Flow::Object;
    use Some::My::Module;
    
    my $obj = Some::My::Module->new(...);
    
    my $loop = Loop::Flow::Object->new(max_count=>..., forks=>..., debug=>...);
    $loop->start($obj, main=>'one', data=>'data', end=>'end',);
    ...



=head1 EXPORT

None.

=head1 METHODS

=cut

=head2 new(max_count=>..., forks=>..., debug=>...)

Options:

=over 4

=item * B<max_count> => <integer> (optional)

    infinitely looping if max_count => 0 || undef (default)

=item * B<forks> => <integer> (optional)

    Limit of forks
    
    No forking, sequentially if forks => 0 || undef (default)



=item * B<debug> => 0|1 (optional)

    0 - no print msg (default)

=back
=cut

sub new {
    my $class = shift;
    my $self = {
        max_count=>undef,
        forks => undef,
        debug => undef,
        @_,
    };
    bless $self, $class;
    return $self;
}

=head2 start($obj, main=>'<main_method>', data=>'<data_method>', end=>'<end_method>',)

Looping/forking for $obj which have methods:

=over 4

=item * B<main> => string '<main_method>' - main code which execute in loop (as child process if forks) (mandatory)

=item * B<data> => string '<data_method>' - hook which get/return data for '<main_method>'

Returning list of data will pass to the main method.

B<Attention>. If you define this method and it's return B<empty list> - WILL STOPS THE LOOPING, but will wait for childs if any.

=item * B<end> => string '<end_method>' - hook which execute when end the '<main_method>' of one loop (child process exit if forks)

=cut

sub start {
    my $self = shift;
    my $obj = shift;
    my %meths = (@_);
    my %stack = ();# для $self->{forks} = undef останется пустой
    my $count = 0;
    #~ while ( %stack != 0 || !$self->{max_count} || $count < $self->{max_count} ) {# ПОЕХАЛИ
    until ( scalar keys %stack == 0 && $self->{max_count} && $count == $self->{max_count} ) {# ПОЕХАЛИ (с)
        #~ print "START: ", (map {"[$_], "} (%stack != 0, !$self->{max_count},  $count < $self->{max_count})),"\n",;
        if ((!$self->{max_count} || $count < $self->{max_count}) && (!$self->{forks} || scalar keys %stack < $self->{forks})) {
            my @data = $self->data($obj, $meths{data}, $count);# данные, отправляемые в основной метод
            last unless @data;
            my $pid = $self->start_main($obj, $meths{main}, @data,);
            $stack{$pid}++ if $pid;
            $count++;
        }
        
        if ($self->{forks} && (my @pids = $self->check_child()) ) {
            delete @stack{ @pids };
        }
        
    }
    
    while (scalar keys %stack) {
        my @pids = $self->check_child();
        delete @stack{ @pids };
    }
}

sub data {
    my $self = shift;
    my $obj = shift;
    my $meth_str = shift;
    my $count = shift;
    
    if ($meth_str) {
        my $meth = $obj->can($meth_str);
        die "Не найден метод [$meth_str] объекта/модуля [$obj]" unless $meth;
        return $obj->$meth(@_);
    } else {
        return $count;
    }
}

sub start_main {#  может не форк
    my $self = shift;
    my $obj = shift;
    my $meth_str = shift;
    
    my $meth = $obj->can($meth_str);
    die "Не найден метод [$meth_str] объекта/модуля [$obj]" unless $meth;

    my $pid = $self->{forks} ? fork() : 0;#
    if( $pid ) {# parent
        #~ print "{$$} PARENT: running child pid={$pid}\n" if $self->{debug};
        return $pid;
    } elsif ($pid == 0) {# child or sequential
        #~ print "make_child: ", Dumper(\@_),
        $obj->$meth(@_);
        
        if ($self->{forks}) {
            print "{$$} CHILD: iam done!\n" if $self->{debug};
            exit 0;
        } else {
            return undef;
        }
    } else {
        die "couldnt fork: $!\n";
    }

}

sub check_child {# просто проверить и вернуть иды завершенных процессов для delete from %stack
	my $self = shift;
	my $pid;
	my @pids = ();
	while (1) {#$pid > 0do
		$pid = waitpid(-1, WNOHANG);
		if ($pid > 0) {
			print "Parent: done child pid=$pid \$?=[$?];\n";
			push(@pids, $pid);
		} else {last;}
	}
	return @pids;
}


=head1 AUTHOR

Mikhail Che, C<< <m.che a@t aukama.dyndns.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-loop-flow at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Loop-Flow>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Loop::Flow::Object


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Loop-Flow-Object>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Loop-Flow-Object>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Loop-Flow-Object>

=item * Search CPAN

L<http://search.cpan.org/dist/Loop-Flow-Object/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mikhail Che.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Loop::Flow::Object
