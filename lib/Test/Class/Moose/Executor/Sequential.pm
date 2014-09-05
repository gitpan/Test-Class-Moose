package Test::Class::Moose::Executor::Sequential;
$Test::Class::Moose::Executor::Sequential::VERSION = '0.58';
# ABSTRACT: Execute tests sequentially

use 5.10.0;
use Moose 2.0000;
use Carp;
use namespace::autoclean;
with 'Test::Class::Moose::Role::Executor';

use Test::Most 0.32 ();

sub runtests {
    my $self = shift;

    my $report = $self->test_report;
    $report->_start_benchmark;
    my @test_classes = $self->test_classes;

    my $builder = $self->test_configuration->builder;
    $builder->plan( tests => scalar @test_classes );

    foreach my $test_class (@test_classes) {
        Test::Most::explain("\nRunning tests for $test_class\n\n");
        $builder->subtest(
            $test_class,
            $self->_tcm_run_test_class($test_class),
        );
    }

    $builder->diag(<<"END") if $self->test_configuration->statistics;
Test instances:  @{[ $report->num_test_instances ]}
Test methods:    @{[ $report->num_test_methods ]}
Total tests run: @{[ $report->num_tests_run ]}
END
    $builder->done_testing;
    $report->_end_benchmark;
    return $self;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::Class::Moose::Executor::Sequential - Execute tests sequentially

=head1 VERSION

version 0.58

=head1 AUTHOR

Curtis "Ovid" Poe <ovid@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Curtis "Ovid" Poe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
