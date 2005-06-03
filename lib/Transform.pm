package Transform;

use strict;
use warnings;

use XML::Parser;

our %xformats;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(%xformats);
our $VERSION = sprintf "%d.%02d", '$Revision$ ' =~ /(\d+)\.(\d+)/;

%xformats= (h => 'html',
            p => 'pod',
            t => 'text');

sub new {
  my $class = shift;
  my %args = @_;

  warn "Formatting file as $args{type}\n";

  my $p = XML::Parser->new(Style => 'Tree');
  my $tree = $p->parsefile($args{file});

  bless { tree => $tree, type => $args{type},
	  level => 0, head => 1, ind => '  ' }, $class . "::$args{type}";
}

sub process {
  my $self = shift;

  my $tree = $self->{tree};

  return $self->top .
    $self->process_node(@$tree) .
      $self->bot;
}

sub process_node {
  my $self = shift;

  my ($type, $content) = @_;

  my $ind = '  ';

  my $str = '';

  if ($type) {
    local $_ = $type;

    my $attrs = shift @$content;

    /^NAME$/ and $str = $self->name($content);
    /^SYNOPSIS$/ and $str = $self->synopsis($content);
    /^DESCRIPTION$/ and $str = $self->description();
    /^VERBATIM$/ and $str = $self->verbatim($content);
    /^TEXT$/ and $str = $self->text($content);
    /^CODE$/ and $str = $self->code($content);
    /^HEAD$/ and $str = $self->head($content);
    /^LIST$/ and do {$str = $self->list($attrs, $content); @$content = ()};
    /^AUTHOR$/ and $str = $self->author();
    /^ANAME$/ and $str = $self->aname($content);
    /^EMAIL$/ and $str = $self->email($content);
    /^SEE_ALSO$/ and $str = $self->see_also($content);

    while (my @node = splice @$content, 0, 2) {
      ++$self->{level};
      ++$self->{head} if $type eq 'SUBSECTION';
      $str .= $self->process_node(@node);
      --$self->{head} if $type eq 'SUBSECTION';
      --$self->{level};
    }
  }

  return $str;
}

sub trim {
  my $self = shift;
  local $_ = shift;

  s/\n/ /g;
  s/^\s+//;
  s/\s+$//;

  $_;
}

package Transform::html;

use Text::Wrap;
our @ISA = qw(Transform);

sub top {
  my $self = shift;
  my $tree = $self->{tree};

  return "<html>\n" .
    "<head>\n" .
      "<title>$tree->[1]->[4]->[2]</title>\n" .
	"</head>\n<body>\n";
}

sub bot {
  my $self = shift;

  return "</body>\n</html>\n";
}

sub name {
  my $self = shift;
  my $content = shift;

  return "<h1>NAME</h1>\n" .
    "<p>$content->[1]</p>\n";
}

sub synopsis {
  my $self = shift;
  my $content = shift;

  return "<h1>SYNOPSIS</h1>\n" .
    "<pre>$content->[1]</pre>\n";
}

sub description {
  my $self = shift;

  return "<h1>DESCRIPTION</h1>\n";
}

sub text {
  my $self = shift;
  my $content = shift;

  return "<p>$content->[1]</p>\n";
}

sub code {
  my $self = shift;
  my $content = shift;

  $content->[1] =~ s/^/    /mg;

  return "<pre>$content->[1]</pre>\n";
}

sub head {
  my $self = shift;
  my $content = shift;

  return "<h$self->{head}>" .
    $self->trim($content->[1]) .
	"</h$self->{head}>\n"
}

sub list {
  my $self = shift;
  my ($attrs, $content) = @_;

  my %list = (bullet => 'ul',
	      numbered => 'ol');

  my $type = $attrs->{TYPE};

  my $str = "<$list{$type}>\n";
  while (my @node = splice @$content, 0, 2) {
    if ($node[0] eq 'ITEM') {
      $str .= "<li>$node[1]->[2]</li>\n";
    }
  }

  return $str . "</$list{$type}>\n";
}

sub author {
  my $self = shift;

  return "<h1>AUTHOR</h1>\n";
}

sub aname {
  my $self = shift;
  my $content = shift;

  return "<p>$content->[1] "
}

sub email {
  my $self = shift;
  my $content = shift;

  return '&lt;' .
    $self->trim($content->[1]) .
	"&gt;</p>\n"
}

sub see_also {
  my $self = shift;

  return "<h1>SEE ALSO</h1>\n";
}

package Transform::text;

use Text::Wrap;
our @ISA = qw(Transform);

sub top {
  my $self = shift;
  my $tree = $self->{tree};

  return "\n", $tree->[1]->[4]->[2], "\n" .
    '-' x length($tree->[1]->[4]->[2]) . "\n\n";
}

sub bot {
  my $self = shift;

  return '';
}

sub name {
  my $self = shift;
  my $content = shift;

  return "NAME\n\n" .
    $self->{ind} . "$content->[1]\n\n";
}

sub synopsis {
  my $self = shift;
  my $content = shift;

  return "SYNOPSIS\n" .
    "$content->[1]\n";
}

sub description {
  my $self = shift;

  return "DESCRIPTION\n\n";
}

sub text {
  my $self = shift;
  my $content = shift;

  return wrap($self->{ind}, $self->{ind},
	      $self->trim($content->[1])) . "\n\n";
}

sub code {
  my $self = shift;
  my $content = shift;

  $content->[1] =~ s/^/    /mg;

  return "$content->[1]\n\n";
}

sub head {
  my $self = shift;
  my $content = shift;

  return $self->trim($content->[1]) . "\n\n";
}

sub list {
  my $self = shift;
  my ($attrs, $content) = @_;

  my $type = $attrs->{TYPE};

  my $str = '';
  my $cnt = 1;
  while (my @node = splice @$content, 0, 2) {
    if ($node[0] eq 'ITEM') {
      my $bul = $type eq 'bullet' ? '*' : $cnt++;
      $str .= "$self->{ind}$bul $node[1]->[2]\n";
    }
  }
  return "$str\n";
}

sub author {
  my $self = shift;

  return "AUTHOR\n\n";
}

sub aname {
  my $self = shift;
  my $content = shift;

  return $self->{ind} . $self->trim($content->[1]) . ' ';
}

sub email {
  my $self = shift;
  my $content = shift;

  return '<' . $self->trim($content->[1]) . ">\n\n";
}

sub see_also {
  my $self = shift;

  return "SEE ALSO\n\n";
}

package Transform::pod;

use Text::Wrap;
our @ISA = qw(Transform);

sub top {
  my $self = shift;
  my $tree = $self->{tree};

  return "=pod\n\n";
}

sub bot {
  my $self = shift;

  return "=cut\n\n";
}

sub name {
  my $self = shift;
  my $content = shift;

  return "=head1 NAME\n\n" .
    "$content->[1]\n\n";
}

sub synopsis {
  my $self = shift;
  my $content = shift;

  return "=head1 SYNOPSIS\n\n" .
    "$content->[1]\n";
}

sub description {
  my $self = shift;

  return "=head1 DESCRIPTION\n\n";
}

sub text {
  my $self = shift;
  my $content = shift;

  return wrap('', '', $self->trim($content->[1])) . "\n\n";
}

sub code {
  my $self = shift;
  my $content = shift;

  $content->[1] =~ s/^/    /mg;

  return "$content->[1]\n\n";
}

sub head {
  my $self = shift;
  my $content = shift;

  return "=head$self->{head} " . $self->trim($content->[1]) . "\n\n";
}

sub list {
  my $self = shift;
  my ($attrs, $content) = @_;

  my $type = $attrs->{TYPE};

  my $bul = $type eq 'bullet' ? '*' : 1;

  my $str = "=over 4\n";
  while (my @node = splice @$content, 0, 2) {
    if ($node[0] eq 'ITEM') {
      $str .= "=item $bul\n$node[1]->[2]\n\n";
    }
  }
  return $str . "=back\n\n";
}

sub author {
  my $self = shift;

  return "=head1 AUTHOR\n\n";
}

sub aname {
  my $self = shift;
  my $content = shift;

  return $self->trim($content->[1]) . ' ';
}

sub email {
  my $self = shift;
  my $content = shift;

  return '<' . $self->trim($content->[1]) . ">\n\n";
}

sub see_also {
  my $self = shift;

  return "=head1 SEE ALSO\n\n";
}

1;
