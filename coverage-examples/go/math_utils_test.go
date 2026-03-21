package main

import "testing"

func TestAdd(t *testing.T) {
	if got := Add(2, 3); got != 5 {
		t.Fatalf("expected 5, got %d", got)
	}
}

func TestMultiply(t *testing.T) {
	if got := Multiply(4, 5); got != 20 {
		t.Fatalf("expected 20, got %d", got)
	}
}

func TestDivide(t *testing.T) {
	if got := Divide(10, 2); got != 5 {
		t.Fatalf("expected 5, got %d", got)
	}
}

func TestClassify(t *testing.T) {
	if got := Classify(-2); got != "negative" {
		t.Fatalf("expected negative, got %s", got)
	}
	if got := Classify(0); got != "zero" {
		t.Fatalf("expected zero, got %s", got)
	}
	if got := Classify(4); got != "even" {
		t.Fatalf("expected even, got %s", got)
	}
}
